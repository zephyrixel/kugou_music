use kugou_sdk::{KugouClient, PlatformProfile, Session};
use serde::{Deserialize, Serialize};
use std::sync::OnceLock;
use tokio::sync::Mutex;

use super::{
    device::build_device,
    dto::{BridgeError, DeviceProfileDto},
};

const SESSION_SCHEMA_VERSION: u32 = 2;
const SESSION_PLATFORM: &str = "lite";

pub(crate) struct KugouRuntime {
    pub(crate) client: KugouClient,
    pub(crate) session: Mutex<Session>,
}

static RUNTIME: OnceLock<KugouRuntime> = OnceLock::new();

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct PersistedSession {
    schema_version: u32,
    platform: String,
    session_json: String,
}

pub(crate) fn initialize(
    profile: DeviceProfileDto,
    persisted: Option<String>,
) -> Result<(), BridgeError> {
    if RUNTIME.get().is_some() {
        log::debug!(target: "kugou_bridge::runtime", "Lite SDK runtime already initialized");
        return Ok(());
    }
    let device = build_device(profile)?;
    let session = match persisted {
        Some(value) => restore(&value, device)?,
        None => Session::new(device),
    };
    let client = KugouClient::builder()
        .platform(PlatformProfile::Lite)
        .build()
        .map_err(BridgeError::from_sdk)?;
    RUNTIME
        .set(KugouRuntime {
            client,
            session: Mutex::new(session),
        })
        .map_err(|_| BridgeError::internal("Lite SDK runtime was already initialized"))?;
    log::info!(target: "kugou_bridge::runtime", "Lite SDK runtime initialized");
    Ok(())
}

pub(crate) fn get() -> Result<&'static KugouRuntime, BridgeError> {
    RUNTIME
        .get()
        .ok_or_else(|| BridgeError::internal("Lite SDK runtime is not initialized"))
}

pub(crate) async fn export() -> Result<String, BridgeError> {
    let runtime = get()?;
    let session = runtime.session.lock().await;
    let session_json = session.export().map_err(BridgeError::from_sdk)?;
    serde_json::to_string(&PersistedSession {
        schema_version: SESSION_SCHEMA_VERSION,
        platform: SESSION_PLATFORM.to_owned(),
        session_json,
    })
    .map_err(|error| BridgeError::internal(error.to_string()))
}

fn restore(
    value: &str,
    mut current_device: kugou_sdk::DeviceIdentity,
) -> Result<Session, BridgeError> {
    let persisted: PersistedSession = serde_json::from_str(value)
        .map_err(|error| BridgeError::session_invalid(error.to_string()))?;
    if persisted.schema_version != SESSION_SCHEMA_VERSION || persisted.platform != SESSION_PLATFORM
    {
        return Err(BridgeError::session_invalid(
            "only schema v2 Lite sessions can be imported",
        ));
    }
    let mut restored = Session::import(&persisted.session_json)
        .map_err(|error| BridgeError::session_invalid(error.to_string()))?;
    if restored.device.mid != current_device.mid || restored.device.guid != current_device.guid {
        return Err(BridgeError::session_invalid(
            "persisted session belongs to a different Android device",
        ));
    }
    if restored.has_dfid() {
        current_device.set_dfid(restored.device.dfid_or_dash());
    }
    restored.device = current_device;
    Ok(restored)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::dto::BridgeErrorKind;
    use kugou_sdk::DeviceIdentity;

    fn envelope(session: &Session, version: u32) -> String {
        serde_json::to_string(&PersistedSession {
            schema_version: version,
            platform: SESSION_PLATFORM.into(),
            session_json: session.export().unwrap(),
        })
        .unwrap()
    }

    #[test]
    fn restore_refreshes_device_facts_and_preserves_server_state() {
        let old_device = DeviceIdentity::builder()
            .device_id("same")
            .brand("Old")
            .dfid("dfid-1")
            .build()
            .unwrap();
        let mut session = Session::new(old_device);
        session.user_id = Some(7);
        session.token = Some("token".into());
        let new_device = DeviceIdentity::builder()
            .device_id("same")
            .brand("New")
            .build()
            .unwrap();

        let restored = restore(&envelope(&session, 2), new_device).unwrap();
        assert_eq!(restored.user_id, Some(7));
        assert_eq!(restored.device.brand.as_deref(), Some("New"));
        assert_eq!(restored.device.dfid_or_dash(), "dfid-1");
    }

    #[test]
    fn restore_rejects_legacy_or_different_device_sessions() {
        let first = Session::new(DeviceIdentity::builder().device_id("one").build().unwrap());
        let second = DeviceIdentity::builder().device_id("two").build().unwrap();
        let legacy = restore(&envelope(&first, 1), second.clone()).unwrap_err();
        let different = restore(&envelope(&first, 2), second).unwrap_err();
        assert!(matches!(legacy.kind, BridgeErrorKind::SessionInvalid));
        assert!(matches!(different.kind, BridgeErrorKind::SessionInvalid));
    }
}
