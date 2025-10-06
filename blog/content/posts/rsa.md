---
title: "Симметричное и асимметричное шифрование: Полное руководство"
description: "Разбираем различия между симметричным и асимметричным шифрованием, алгоритмы, создателей и практическое применение"
date: 2025-10-05
tldr: "Симметричное шифрование использует один ключ для шифрования/расшифровки (AES, ChaCha20), асимметричное - пару ключей (RSA, ECC). Симметричное - для больших данных, асимметричное - для обмена ключами и цифровых подписей"
draft: false
tags: ["криптография", "шифрование", "безопасность", "ssl", "gpg"]
toc: true
---

# Симметричное и асимметричное шифрование: Выбор правильного подхода

Криптография делится на два основных типа шифрования: симметричное и асимметричное. Понимание различий между ними критически важно для построения безопасных систем.

## Основные различия

### Симметричное шифрование
- **Один ключ** для шифрования и расшифровки
- **Высокая скорость** обработки данных
- **Эффективно** для больших объемов данных
- **Проблема**: безопасная передача ключа

### Асимметричное шифрование
- **Пара ключей**: публичный и приватный
- **Медленнее** симметричного шифрования
- **Решает проблему** передачи ключей
- **Идеально** для цифровых подписей и обмена ключами

---

## Симметричное шифрование

### Принцип работы
```python
# Простая аналогия
ключ = "СЕКРЕТНЫЙ_КОД"

зашифрованное_сообщение = шифровать(сообщение, ключ)
расшифрованное_сообщение = расшифровать(зашифрованное_сообщение, ключ)
```

### Основные алгоритмы и создатели

#### 1. AES (Advanced Encryption Standard)
- **Создатель**: Винсент Рэймен и Йоан Даймен (Бельгия)
- **Год**: 2001 (выбран NIST как стандарт)
- **Размеры ключа**: 128, 192, 256 бит
- **Тип**: Блочный шифр
- **Использование**: SSL/TLS, VPN, шифрование дисков

```php
<?php
// Пример AES в PHP
$data = "Секретные данные";
$key = random_bytes(32); // AES-256
$iv = random_bytes(16);

$encrypted = openssl_encrypt($data, 'aes-256-cbc', $key, 0, $iv);
$decrypted = openssl_decrypt($encrypted, 'aes-256-cbc', $key, 0, $iv);
```

#### 2. ChaCha20
- **Создатель**: Дэниел Бернштейн (США)
- **Год**: 2008
- **Тип**: Поточный шифр
- **Преимущество**: Высокая скорость на мобильных устройствах
- **Использование**: TLS 1.3, современные VPN

#### 3. Salsa20
- **Создатель**: Дэниел Бернштейн
- **Год**: 2005
- **Предшественник** ChaCha20

#### 4. 3DES (Triple DES)
- **Основан на**: DES (1970-е)
- **Создатель IBM**, доработан NIST
- **Сейчас**: Устарел, не рекомендуется

#### 5. Blowfish
- **Создатель**: Брюс Шнайер
- **Год**: 1993
- **Преемник**: Twofish

---

## Асимметричное шифрование

### Принцип работы
```python
# Генерация пары ключей
приватный_ключ, публичный_ключ = сгенерировать_пару_ключей()

# Шифрование публичным ключом
зашифрованное = шифровать(сообщение, публичный_ключ)

# Расшифровка приватным ключом
расшифрованное = расшифровать(зашифрованное, приватный_ключ)
```

### Основные алгоритмы и создатели

#### 1. RSA (Rivest–Shamir–Adleman)
- **Создатели**: Рон Ривест, Ади Шамир, Леонард Адлеман (MIT)
- **Год**: 1977
- **Основа**: Проблема факторизации больших чисел
- **Размеры ключа**: 2048, 3072, 4096 бит
- **Использование**: SSL/TLS, PGP, цифровые подписи

```php
<?php
// Пример генерации RSA ключей в PHP
$config = array(
    "private_key_bits" => 2048,
    "private_key_type" => OPENSSL_KEYTYPE_RSA,
);

// Генерация пары ключей
$keyPair = openssl_pkey_new($config);

// Экспорт приватного ключа
openssl_pkey_export($keyPair, $privateKey);

// Получение публичного ключа
$publicKey = openssl_pkey_get_details($keyPair)['key'];
```

#### 2. ECC (Elliptic Curve Cryptography)
- **Теоретическая основа**: Нил Коблиц, Виктор Миллер (1985)
- **Практическое применение**: с 2000-х
- **Преимущество**: Меньшие ключи при той же безопасности
- **Алгоритмы**: ECDSA, ECDH, EdDSA

#### 3. ElGamal
- **Создатель**: Тахар Эль-Гамаль
- **Год**: 1985
- **Основа**: Проблема дискретного логарифмирования
- **Использование**: PGP, GnuPG

#### 4. DSA (Digital Signature Algorithm)
- **Создатель**: NIST
- **Год**: 1991
- **Специализация**: Только для цифровых подписей

---

## Сравнительная таблица

| Параметр | Симметричное | Асимметричное |
|----------|--------------|---------------|
| **Количество ключей** | 1 | 2 (публичный + приватный) |
| **Скорость** | Высокая | Медленная (в 100-1000 раз медленнее) |
| **Размер ключа** | 128-256 бит | 2048-4096 бит (RSA) |
| **Безопасность** | Зависит от секретности ключа | Зависит от сложности математических задач |
| **Использование** | Шифрование данных | Обмен ключами, цифровые подписи |

### Сравнение размеров ключей

| Алгоритм | Размер ключа | Эквивалентная стойкость |
|----------|--------------|------------------------|
| AES-128 | 128 бит | 3072-бит RSA |
| AES-256 | 256 бит | 15360-бит RSA |
| RSA | 2048 бит | 112-бит симметричный |
| ECC | 256 бит | 128-бит симметричный |

---

## Когда какое шифрование использовать?

### Используйте симметричное шифрование когда:

#### 1. Шифрование больших объемов данных
```php
<?php
// Шифрование файла с помощью AES
function encryptFile(string $inputFile, string $outputFile, string $key): void {
    $iv = random_bytes(16);
    $cipherText = openssl_encrypt(
        file_get_contents($inputFile),
        'aes-256-cbc',
        $key,
        OPENSSL_RAW_DATA,
        $iv
    );
    file_put_contents($outputFile, $iv . $cipherText);
}
```

#### 2. Шифрование баз данных
```sql
-- Пример: шифрование поля в базе данных
UPDATE users SET
    credit_card = AES_ENCRYPT('4111111111111111', 'encryption_key')
WHERE id = 1;
```

#### 3. VPN туннели
```
OpenVPN, WireGuard используют симметричное шифрование
для защиты всего трафика через туннель
```

#### 4. Дисковое шифрование
```
BitLocker, LUKS, FileVault используют AES
для шифрования целых разделов диска
```

### Используйте асимметричное шифрование когда:

#### 1. Безопасный обмен ключами
```php
<?php
// Гибридный подход: асимметричное + симметричное
class SecureMessage {
    public static function send($message, $recipientPublicKey): string {
        // 1. Генерируем случайный симметричный ключ
        $sessionKey = random_bytes(32);

        // 2. Шифруем сообщение симметричным ключом
        $encryptedMessage = openssl_encrypt(
            $message,
            'aes-256-gcm',
            $sessionKey,
            OPENSSL_RAW_DATA,
            $iv,
            $tag
        );

        // 3. Шифруем симметричный ключ асимметрично
        openssl_public_encrypt($sessionKey, $encryptedKey, $recipientPublicKey);

        return base64_encode($encryptedKey) . ':' .
               base64_encode($iv) . ':' .
               base64_encode($encryptedMessage) . ':' .
               base64_encode($tag);
    }
}
```

#### 2. Цифровые подписи
```php
<?php
class DigitalSignature {
    public static function sign($data, $privateKey): string {
        openssl_sign($data, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        return base64_encode($signature);
    }

    public static function verify($data, $signature, $publicKey): bool {
        return openssl_verify(
            $data,
            base64_decode($signature),
            $publicKey,
            OPENSSL_ALGO_SHA256
        ) === 1;
    }
}

// Использование
$data = "Важный контракт";
$signature = DigitalSignature::sign($data, $privateKey);
$isValid = DigitalSignature::verify($data, $signature, $publicKey);
```

#### 3. Аутентификация
```
SSH ключи, SSL/TLS сертификаты используют
асимметричное шифрование для проверки подлинности
```

#### 4. Криптовалюты
```
Биткоин, Ethereum используют ECC (secp256k1)
для создания адресов и подписи транзакций
```

---

## Гибридные системы: Лучшее из двух миров

### Как работает SSL/TLS

```php
<?php
// Упрощенная схема TLS handshake
class TLSHandshake {
    public function performHandshake(): void {
        // 1. Клиент отправляет ClientHello
        $clientRandom = random_bytes(32);

        // 2. Сервер отведает ServerHello + сертификат
        $serverRandom = random_bytes(32);
        $serverCertificate = $this->getServerCertificate();

        // 3. Клиент проверяет сертификат
        if (!$this->verifyCertificate($serverCertificate)) {
            throw new Exception("Invalid certificate");
        }

        // 4. Клиент генерирует pre-master secret
        $preMasterSecret = random_bytes(48);

        // 5. Шифруем pre-master secret публичным ключом сервера
        $encryptedPreMaster = $this->encryptWithPublicKey(
            $preMasterSecret,
            $serverCertificate['publicKey']
        );

        // 6. Обе стороны вычисляют master secret
        $masterSecret = $this->computeMasterSecret(
            $preMasterSecret,
            $clientRandom,
            $serverRandom
        );

        // 7. Генерация симметричных ключей из master secret
        $sessionKeys = $this->generateSessionKeys($masterSecret);

        // 8. Дальнейшая коммуникация использует симметричное шифрование
        $this->startEncryptedCommunication($sessionKeys);
    }
}
```

### Практический пример: Защищенный мессенджер

```php
<?php
class SecureMessenger {
    private $sessionKey;
    private $iv;

    public function __construct(
        private string $myPrivateKey,
        private string $theirPublicKey
    ) {}

    public function establishSession(): void {
        // Генерация сессионного ключа
        $this->sessionKey = random_bytes(32);
        $this->iv = random_bytes(16);

        // Шифруем сессионный ключ для получателя
        openssl_public_encrypt(
            $this->sessionKey,
            $encryptedSessionKey,
            $this->theirPublicKey
        );

        // В реальности отправили бы $encryptedSessionKey получателю
        file_put_contents('session_key.bin', $encryptedSessionKey);
    }

    public function encryptMessage(string $message): string {
        return openssl_encrypt(
            $message,
            'aes-256-gcm',
            $this->sessionKey,
            OPENSSL_RAW_DATA,
            $this->iv,
            $tag
        ) . ':' . base64_encode($tag);
    }

    public function decryptMessage(string $encryptedMessage): string {
        list($ciphertext, $tag) = explode(':', $encryptedMessage);

        return openssl_decrypt(
            $ciphertext,
            'aes-256-gcm',
            $this->sessionKey,
            OPENSSL_RAW_DATA,
            $this->iv,
            base64_decode($tag)
        );
    }
}
```

---

## Рекомендации по выбору алгоритмов

### Для симметричного шифрования (2024+)
- **Рекомендуется**: AES-256-GCM, ChaCha20-Poly1305
- **Допустимо**: AES-128-GCM
- **Избегать**: DES, 3DES, RC4

### Для асимметричного шифрования (2024+)
- **Рекомендуется**: ECC (P-256, Curve25519), RSA-3072+
- **Допустимо**: RSA-2048
- **Избегать**: RSA-1024, DSA

### Для хеширования
- **Рекомендуется**: SHA-256, SHA-3, BLAKE2
- **Избегать**: MD5, SHA-1

---

## Исторические вехи криптографии

- **1976**: Диффи-Хеллман - первый протокол асимметричного шифрования
- **1977**: RSA - первая практическая асимметричная система
- **1977**: DES - первый стандарт симметричного шифрования
- **1991**: PGP - первая доступная система шифрования для масс
- **2001**: AES - современный стандарт симметричного шифрования
- **2008**: Биткоин - массовое применение ECC в криптовалютах

## Заключение

**Симметричное шифрование** - ваш выбор для эффективного шифрования данных, когда ключ можно безопасно передать.

**Асимметричное шифрование** - решает проблему распределения ключей и обеспечивает цифровые подписи.

**На практике** всегда используйте гибридный подход:
- Асимметричное для установления сессии и аутентификации
- Симметричное для шифрования основного трафика

Правильное понимание и применение обоих типов шифрования - основа построения безопасных современных систем.

---

*Интересуетесь практическим применением шифрования? Читайте наши статьи о [GPG шифровании](/posts/gpg-guide) и [SSL/TLS настройке](/posts/ssl-tls-guide).*
