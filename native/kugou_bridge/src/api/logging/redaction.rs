// SDK Trace records are strings, not structured events. Strip credential fields
// before they cross the writer boundary, including quoted JSON and raw headers.
pub(super) fn redact(message: &str) -> String {
    const KEYS: &[&str] = &[
        "sessionjson",
        "session_json",
        "uuid",
        "code",
        "access_token",
        "vip_token",
        "authorization",
        "cookie",
        "password",
        "passwd",
        "signature",
        "sms_code",
        "smscode",
        "verify_code",
        "android_id",
        "androidid",
        "device_id",
        "deviceid",
        "token",
        "dfid",
        "guid",
        "mid",
    ];
    let lower = message.to_ascii_lowercase();
    let bytes = message.as_bytes();
    let mut ranges = Vec::new();
    for key in KEYS {
        for (start, _) in lower.match_indices(key) {
            if start > 0 && (bytes[start - 1].is_ascii_alphanumeric() || bytes[start - 1] == b'_') {
                continue;
            }
            let mut index = start + key.len();
            if index < bytes.len() && (bytes[index].is_ascii_alphanumeric() || bytes[index] == b'_')
            {
                continue;
            }
            if bytes.get(index) == Some(&b'"') || bytes.get(index) == Some(&b'\'') {
                index += 1;
            }
            while bytes.get(index).is_some_and(u8::is_ascii_whitespace) {
                index += 1;
            }
            if !matches!(bytes.get(index), Some(b':' | b'=')) {
                continue;
            }
            index += 1;
            while bytes.get(index).is_some_and(u8::is_ascii_whitespace) {
                index += 1;
            }
            let quoted = bytes
                .get(index)
                .copied()
                .filter(|ch| *ch == b'"' || *ch == b'\'');
            if quoted.is_some() {
                index += 1;
            }
            let value_start = index;
            while index < bytes.len() {
                let byte = bytes[index];
                if let Some(quote) = quoted {
                    if byte == quote {
                        break;
                    }
                    if byte == b'\\' && index + 1 < bytes.len() {
                        index += 2;
                        continue;
                    }
                } else if *key == "authorization" || *key == "cookie" {
                    if byte == b'\n' || byte == b'\r' {
                        break;
                    }
                } else if byte.is_ascii_whitespace() || matches!(byte, b'&' | b',' | b';' | b'}') {
                    break;
                }
                index += 1;
            }
            if *key == "code"
                && !(quoted.is_some()
                    && (4..=8).contains(&(index - value_start))
                    && bytes[value_start..index].iter().all(u8::is_ascii_digit))
            {
                continue;
            }
            if index > value_start {
                ranges.push((value_start, index));
            }
        }
    }
    ranges.sort_unstable();
    let mut output = String::with_capacity(message.len());
    let mut copied = 0;
    for (start, end) in ranges {
        if start < copied {
            continue;
        }
        output.push_str(&message[copied..start]);
        output.push_str("***");
        copied = end;
    }
    output.push_str(&message[copied..]);
    // Phone numbers may occur without a field label.
    let mut redacted = String::with_capacity(output.len());
    let chars: Vec<char> = output.chars().collect();
    let mut index = 0;
    while index < chars.len() {
        if chars[index] == '1'
            && index + 11 <= chars.len()
            && chars[index..index + 11].iter().all(char::is_ascii_digit)
            && (index == 0 || !chars[index - 1].is_ascii_digit())
            && (index + 11 == chars.len() || !chars[index + 11].is_ascii_digit())
        {
            redacted.extend(&chars[index..index + 3]);
            redacted.push_str("****");
            redacted.extend(&chars[index + 7..index + 11]);
            index += 11;
        } else {
            redacted.push(chars[index]);
            index += 1;
        }
    }
    redacted
}

#[cfg(test)]
mod tests {
    use super::redact;
    #[test]
    fn redacts_json_bearer_and_device_fields_without_losing_business_codes() {
        let value = redact(r#"body={"token":"secret","code":20017,"dfid":"device-secret"}"#);
        assert!(!value.contains("secret"));
        assert!(value.contains("20017"));
        assert!(
            !redact(r#"{"code":"123456","uuid":"device","sessionJson":"session"}"#)
                .contains("123456")
        );
        assert_eq!(redact("Authorization: Bearer secret"), "Authorization: ***");
        assert_eq!(redact("Cookie: first=secret; second=secret"), "Cookie: ***");
        assert_eq!(redact("mobile=13800138000"), "mobile=138****8000");
    }
}
