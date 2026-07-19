use kugou_sdk::KugouError;

use super::dto::{BridgeError, BridgeErrorKind};

impl BridgeError {
    pub(super) fn invalid_argument(message: impl Into<String>) -> Self {
        Self {
            kind: BridgeErrorKind::InvalidArgument,
            message: message.into(),
            code: None,
            retryable: false,
        }
    }

    pub(super) fn session_invalid(message: impl Into<String>) -> Self {
        Self {
            kind: BridgeErrorKind::SessionInvalid,
            message: message.into(),
            code: None,
            retryable: false,
        }
    }

    pub(super) fn upstream(message: impl Into<String>, retryable: bool) -> Self {
        Self {
            kind: BridgeErrorKind::Upstream,
            message: message.into(),
            code: None,
            retryable,
        }
    }

    pub(super) fn internal(message: impl Into<String>) -> Self {
        Self {
            kind: BridgeErrorKind::Internal,
            message: message.into(),
            code: None,
            retryable: false,
        }
    }

    pub(super) fn from_sdk(error: KugouError) -> Self {
        match error {
            KugouError::InvalidArgument(message) => {
                Self::invalid_argument(format!("invalid argument: {message}"))
            }
            KugouError::AuthenticationRequired => Self {
                kind: BridgeErrorKind::AuthenticationRequired,
                message: "authentication is required for this operation".into(),
                code: None,
                retryable: false,
            },
            KugouError::Transport(error) => Self {
                kind: BridgeErrorKind::Transport,
                // kugou_sdk strips the request URL before wrapping reqwest errors.
                message: format!("HTTP transport failed: {error}"),
                code: None,
                retryable: true,
            },
            KugouError::Http {
                endpoint,
                status: 404,
                ..
            } => Self {
                kind: BridgeErrorKind::Unsupported,
                message: format!("KuGou endpoint {endpoint} returned HTTP 404"),
                code: Some(404),
                retryable: false,
            },
            KugouError::Http {
                endpoint, status, ..
            } => Self {
                kind: BridgeErrorKind::Upstream,
                message: format!("KuGou endpoint {endpoint} returned HTTP {status}"),
                code: Some(i64::from(status)),
                retryable: status >= 500,
            },
            KugouError::Protocol {
                endpoint, message, ..
            } => Self::internal(format!("invalid response from {endpoint}: {message}")),
            KugouError::Business { code, message, .. } if code == 20017 || code == 20018 => Self {
                kind: BridgeErrorKind::AuthenticationExpired,
                message: format!("KuGou business error {code}: {message}"),
                code: Some(code),
                retryable: false,
            },
            KugouError::Business { code, message, .. } => Self {
                kind: BridgeErrorKind::Upstream,
                message: format!("KuGou business error {code}: {message}"),
                code: Some(code),
                retryable: false,
            },
            KugouError::SecurityChallenge(challenge) => Self {
                kind: BridgeErrorKind::SecurityChallenge,
                message: format!("security verification required: {}", challenge.code),
                code: challenge.code.parse().ok(),
                retryable: true,
            },
            KugouError::UnexpectedResponse {
                endpoint, issue, ..
            } => Self::internal(format!("unexpected response from {endpoint}: {issue}")),
            KugouError::Serialization(error) => {
                Self::internal(format!("serialization failed: {error}"))
            }
            KugouError::Decode(message) => {
                Self::internal(format!("cryptographic or lyric decoding failed: {message}"))
            }
            KugouError::Configuration(message) => {
                Self::internal(format!("client configuration error: {message}"))
            }
            _ => Self::internal("unexpected SDK error"),
        }
    }
}

#[cfg(test)]
mod tests {
    use kugou_sdk::SecurityChallenge;
    use serde_json::json;

    use super::*;

    const SECRET: &str = "secret-token-that-must-not-leak";

    #[test]
    fn http_response_body_is_not_exposed_to_flutter() {
        let bridge = BridgeError::from_sdk(KugouError::Http {
            endpoint: "/api/v1/song".into(),
            status: 500,
            body: format!("token={SECRET}"),
        });

        assert_eq!(bridge.code, Some(500));
        assert!(!bridge.message.contains(SECRET));
        assert!(!bridge.message.contains("token="));
    }

    #[test]
    fn business_and_challenge_bodies_are_not_exposed_to_flutter() {
        let business = BridgeError::from_sdk(KugouError::Business {
            code: 123,
            message: "request rejected".into(),
            body: json!({"token": SECRET}),
        });
        let challenge = serde_json::from_value::<SecurityChallenge>(json!({
            "code": "911",
            "body": {"cookie": SECRET},
        }))
        .expect("security challenge fixture should deserialize");
        let challenge = BridgeError::from_sdk(KugouError::SecurityChallenge(challenge));

        assert!(!business.message.contains(SECRET));
        assert!(!challenge.message.contains(SECRET));
        assert_eq!(challenge.code, Some(911));
    }
}
