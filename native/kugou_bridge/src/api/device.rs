use kugou_sdk::{DeviceIdentity, DeviceIdentityBuilder};
use serde_json::{Map, Value, json};

use super::dto::{BridgeError, DeviceProfileDto};

pub(crate) fn build_device(profile: DeviceProfileDto) -> Result<DeviceIdentity, BridgeError> {
    let fingerprint_extra = fingerprint_extra(&profile);
    let device_id = required(profile.device_id, "device id")?;
    let mut builder = DeviceIdentity::builder().device_id(device_id);
    builder = optional(
        builder,
        profile.android_id,
        DeviceIdentityBuilder::android_id,
    );
    builder = optional(builder, profile.brand, DeviceIdentityBuilder::brand);
    builder = optional(builder, profile.model, DeviceIdentityBuilder::model);
    builder = optional(
        builder,
        profile.manufacturer,
        DeviceIdentityBuilder::manufacturer,
    );
    builder
        .fingerprint_extra(fingerprint_extra)
        .build()
        .map_err(BridgeError::from_sdk)
}

fn required(value: String, name: &str) -> Result<String, BridgeError> {
    let value = value.trim();
    if value.is_empty() {
        Err(BridgeError::invalid_argument(format!(
            "{name} cannot be empty"
        )))
    } else {
        Ok(value.to_owned())
    }
}

fn optional(
    builder: DeviceIdentityBuilder,
    value: Option<String>,
    apply: fn(DeviceIdentityBuilder, String) -> DeviceIdentityBuilder,
) -> DeviceIdentityBuilder {
    match value
        .map(|value| value.trim().to_owned())
        .filter(|v| !v.is_empty())
    {
        Some(value) => apply(builder, value),
        None => builder,
    }
}

fn fingerprint_extra(profile: &DeviceProfileDto) -> Value {
    let mut extra = Map::new();
    insert(&mut extra, "basebandVer", profile.baseband_version.clone());
    insert(&mut extra, "availableRamSize", profile.available_ram_bytes);
    insert(
        &mut extra,
        "availableRomSize",
        profile.available_internal_storage_bytes,
    );
    insert(
        &mut extra,
        "availableSDSize",
        profile.available_external_storage_bytes,
    );
    insert(&mut extra, "batteryLevel", profile.battery_level);
    insert(&mut extra, "batteryStatus", profile.battery_status);
    extra.insert("accelerometer".into(), json!(profile.has_accelerometer));
    extra.insert("gravity".into(), json!(profile.has_gravity));
    extra.insert("gyroscope".into(), json!(profile.has_gyroscope));
    extra.insert("light".into(), json!(profile.has_light));
    extra.insert("magnetic".into(), json!(profile.has_magnetic_field));
    extra.insert("orientation".into(), json!(profile.has_orientation));
    extra.insert("pressure".into(), json!(profile.has_pressure));
    extra.insert("step_counter".into(), json!(profile.has_step_counter));
    extra.insert("temperature".into(), json!(profile.has_ambient_temperature));
    Value::Object(extra)
}

fn insert<T: serde::Serialize>(map: &mut Map<String, Value>, key: &str, value: Option<T>) {
    if let Some(value) = value {
        map.insert(key.to_owned(), json!(value));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn profile() -> DeviceProfileDto {
        DeviceProfileDto {
            device_id: "android-id-1".into(),
            android_id: Some("android-id-1".into()),
            brand: Some("Google".into()),
            model: Some("Pixel 9".into()),
            manufacturer: Some("Google".into()),
            baseband_version: Some("radio-1".into()),
            available_ram_bytes: Some(1_000),
            available_internal_storage_bytes: Some(2_000),
            available_external_storage_bytes: Some(3_000),
            battery_level: Some(80),
            battery_status: Some(3),
            has_accelerometer: true,
            has_gravity: true,
            has_gyroscope: true,
            has_light: true,
            has_magnetic_field: true,
            has_orientation: false,
            has_pressure: false,
            has_step_counter: true,
            has_ambient_temperature: false,
        }
    }

    #[test]
    fn profile_builds_stable_real_device_identity() {
        let first = build_device(profile()).unwrap();
        let second = build_device(profile()).unwrap();
        assert_eq!(first.mid, second.mid);
        assert_eq!(first.guid, second.guid);
        assert_eq!(first.uuid, first.guid);
        assert_eq!(first.model.as_deref(), Some("Pixel 9"));
        assert_eq!(first.android_id.as_deref(), Some("android-id-1"));
        let extra = first.fingerprint_extra.unwrap();
        assert_eq!(extra["availableRamSize"], 1_000);
        assert_eq!(extra["gyroscope"], true);
    }
}
