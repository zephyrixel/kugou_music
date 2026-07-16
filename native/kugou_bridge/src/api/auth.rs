use kugou_sdk::Session;

use super::{
    dto::{AuthStateDto, BridgeError, SmsLoginResultDto},
    runtime,
};

pub(crate) async fn auth_state() -> Result<AuthStateDto, BridgeError> {
    let runtime = runtime::get()?;
    let session = runtime.session.lock().await;
    Ok(snapshot(&session))
}

pub(crate) async fn ensure_device_registered() -> Result<AuthStateDto, BridgeError> {
    register(false).await
}

pub(crate) async fn register_device() -> Result<AuthStateDto, BridgeError> {
    register(true).await
}

async fn register(force: bool) -> Result<AuthStateDto, BridgeError> {
    let runtime = runtime::get()?;
    let mut session = runtime.session.lock().await;
    if force || !session.has_dfid() {
        runtime
            .client
            .auth()
            .register_dev(&mut session, None)
            .await
            .map_err(BridgeError::from_sdk)?;
    }
    Ok(snapshot(&session))
}

pub(crate) async fn send_sms_code(mobile: String) -> Result<(), BridgeError> {
    let runtime = runtime::get()?;
    let mut session = runtime.session.lock().await;
    if !session.has_dfid() {
        return Err(BridgeError::invalid_argument(
            "device must be registered before requesting an SMS code",
        ));
    }
    runtime
        .client
        .auth()
        .send_sms_code(&mut session, &mobile)
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(())
}

pub(crate) async fn login_by_sms(
    mobile: String,
    code: String,
) -> Result<SmsLoginResultDto, BridgeError> {
    let runtime = runtime::get()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .auth()
        .login_by_sms(&mut session, &mobile, &code)
        .await
        .map_err(BridgeError::from_sdk)?;
    if !session.is_authenticated() {
        return Err(BridgeError::internal(
            "SMS login returned without an authenticated session",
        ));
    }
    let fingerprint_warning = if session.has_dfid() {
        None
    } else {
        runtime
            .client
            .auth()
            .register_dev(&mut session, None)
            .await
            .err()
            .map(|error| error.to_string())
    };
    Ok(SmsLoginResultDto {
        auth: snapshot(&session),
        fingerprint_warning,
    })
}

pub(crate) async fn refresh_login() -> Result<AuthStateDto, BridgeError> {
    let runtime = runtime::get()?;
    let mut session = runtime.session.lock().await;
    runtime
        .client
        .auth()
        .refresh_token(&mut session)
        .await
        .map_err(BridgeError::from_sdk)?;
    Ok(snapshot(&session))
}

pub(crate) async fn logout() -> Result<AuthStateDto, BridgeError> {
    let runtime = runtime::get()?;
    let mut session = runtime.session.lock().await;
    let device = session.device.clone();
    *session = Session::new(device);
    Ok(snapshot(&session))
}

fn snapshot(session: &Session) -> AuthStateDto {
    AuthStateDto {
        authenticated: session.is_authenticated(),
        user_id: session.user_id,
        vip_type: session.vip_type,
        fingerprint_registered: session.has_dfid(),
    }
}
