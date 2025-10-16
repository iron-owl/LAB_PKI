# Описание стенда

Лабораторная работа подготовлена на основе [статьи](https://jamielinux.com/docs/openssl-certificate-authority/index.html).

# Подготовка и запуск стенда

Выполнить сборку базового образа контейнера с Ubuntu:
```bash
root@vm-ubnt:/opt/lab_pki# docker build -t base-ubuntu-ca ./base
[+] Building 0.6s (11/11) FINISHED                                                                                                                                                                              docker:default
 => [internal] load build definition from Dockerfile                                                                                                                                                                      0.0s
 => => transferring dockerfile: 791B                                                                                                                                                                                      0.0s
 => [internal] load metadata for docker.io/library/ubuntu:24.04                                                                                                                                                           0.5s
 => [internal] load .dockerignore                                                                                                                                                                                         0.0s
 => => transferring context: 2B                                                                                                                                                                                           0.0s
 => [1/6] FROM docker.io/library/ubuntu:24.04@sha256:66460d557b25769b102175144d538d88219c077c678a49af4afca6fbfc1b5252                                                                                                     0.0s
 => [internal] load build context                                                                                                                                                                                         0.0s
 => => transferring context: 60B                                                                                                                                                                                          0.0s
 => CACHED [2/6] RUN apt-get update &&     apt-get install -y --no-install-recommends         openssh-server sudo vim curl net-tools ca-certificates &&     mkdir /var/run/sshd &&     rm -rf /var/lib/apt/lists/*        0.0s
 => CACHED [3/6] RUN useradd -m -s /bin/bash student &&     echo "student:student" | chpasswd &&     usermod -aG sudo student                                                                                             0.0s
 => CACHED [4/6] COPY sshd_config /etc/ssh/sshd_config                                                                                                                                                                    0.0s
 => CACHED [5/6] COPY init.sh /opt/init.sh                                                                                                                                                                                0.0s
 => CACHED [6/6] RUN chmod +x /opt/init.sh                                                                                                                                                                                0.0s
 => exporting to image                                                                                                                                                                                                    0.0s
 => => exporting layers                                                                                                                                                                                                   0.0s
 => => writing image sha256:b002cec8cb492b1352d3fdfee1d7f383bf1dbb56e2a001d2d2f41331d8b603bb                                                                                                                              0.0s
 => => naming to docker.io/library/base-ubuntu-ca                                                                                                                                                                         0.0s
```

Запустить контейнеры:
```bash
root@vm-ubnt:/opt/lab_pki# docker compose up -d
[+] Running 4/4
 ✔ Container lab_pki-root-ca-1          Started                                                                                                                                                                           0.5s
 ✔ Container lab_pki-intermediate-ca-1  Started                                                                                                                                                                           0.8s
 ✔ Container lab_pki-ocsp-1             Started                                                                                                                                                                           1.1s
 ✔ Container lab_pki-nginx-server-1     Started                                                                                                                                                                           1.5s
```

Проверка работоспособности:
```bash
root@vm-ubnt:/opt/lab_pki# docker compose ps
NAME                        IMAGE                     COMMAND                  SERVICE           CREATED         STATUS         PORTS
lab_pki-intermediate-ca-1   lab_pki-intermediate-ca   "/opt/init.sh"           intermediate-ca   5 seconds ago   Up 4 seconds   0.0.0.0:22001->22/tcp, :::22001->22/tcp
lab_pki-nginx-server-1      lab_pki-nginx-server      "/docker-entrypoint.…"   nginx-server      5 seconds ago   Up 3 seconds   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 80/tcp, 0.0.0.0:8443->8443/tcp, :::8443->8443/tcp
lab_pki-ocsp-1              lab_pki-ocsp              "/opt/init.sh"           ocsp              5 seconds ago   Up 3 seconds   0.0.0.0:22002->22/tcp, :::22002->22/tcp
lab_pki-root-ca-1           lab_pki-root-ca           "/opt/init.sh"           root-ca           5 seconds ago   Up 4 seconds   0.0.0.0:22000->22/tcp, :::22000->22/tcp
```

# Развёртывание инфраструктуры PKI
## Подготовка корневого центра сертификации

Подключение к контейнеру, переход в рабочий каталог (`/root/ca`), просмотр содержимого:
```bash
root@vm-ubnt:/opt/lab_pki# ssh student@127.0.0.1 -p 22000
student@127.0.0.1's password:
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.8.0-79-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Wed Oct 15 10:12:20 2025 from 172.23.0.1
student@96520cbdbfc0:~$ sudo bash
[sudo] password for student:
root@96520cbdbfc0:/home/student# pwd
/home/student
root@96520cbdbfc0:/home/student# cd /root/ca
root@96520cbdbfc0:~/ca# ls -la
total 32
drwxr-xr-x 6 root root 4096 Oct 15 10:21 .
drwx------ 1 root root 4096 Oct 15 10:12 ..
drwxr-xr-x 2 root root 4096 Oct 15 09:51 certs
drwxr-xr-x 2 root root 4096 Oct 15 09:51 crl
-rw-r--r-- 1 root root    0 Oct 15 10:08 index.txt
drwxr-xr-x 2 root root 4096 Oct 15 09:51 newcerts
-rw-r--r-- 1 root root 2299 Oct 14 14:53 openssl.cnf
drwx------ 2 root root 4096 Oct 15 10:16 private
-rw-r--r-- 1 root root    5 Oct 15 10:08 serial

root@96520cbdbfc0:~/ca# cat index.txt
root@96520cbdbfc0:~/ca# cat serial
1000
```

Файлы `index.txt` и `serial` - плоская база для отслеживания подписанных сертификатов.

### Генерация ключа

```bash
root@7003d8c94d54:~/ca# openssl genrsa -aes256 -out private/ca.key.pem 4096
chmod 400 private/ca.key.pem
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
```

В качестве pass phrase можно использовать произвольную последовательность, например, `123123`.

### Генерация корневого сертификата

Генерация сертификата:
```bash
root@96520cbdbfc0:~/ca# openssl req -config openssl.cnf \
-key private/ca.key.pem \
-new -x509 -days 7300 -sha256 -extensions v3_ca \
-out certs/ca.cert.pem
Enter pass phrase for private/ca.key.pem:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [RU]:RU
State or Province Name [Moscow]:Moscow
Locality Name [Moscow]:Moscow
Organization Name [LAB]:LAB
Organizational Unit Name [LAB Root CA]:
Common Name [LAB Root CA]:LAB Root CA
Email Address [rootca@lab.local]:rootca@lab.local
root@96520cbdbfc0:~/ca#
```

Просмотр сертификата:
```bash
root@96520cbdbfc0:~/ca# openssl x509 -noout -text -in certs/ca.cert.pem
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            14:dc:42:5b:1f:f2:85:df:75:2a:14:36:00:0b:45:6b:3c:74:22:99
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = RU, ST = Moscow, L = Moscow, O = LAB, OU = LAB Root CA, CN = LAB Root CA, emailAddress = rootca@lab.local
        Validity
            Not Before: Oct 15 10:23:50 2025 GMT
            Not After : Oct 10 10:23:50 2045 GMT
        Subject: C = RU, ST = Moscow, L = Moscow, O = LAB, OU = LAB Root CA, CN = LAB Root CA, emailAddress = rootca@lab.local
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (4096 bit)
                Modulus:
                    00:ab:1e:35:b3:d5:dd:05:e2:f5:57:bd:3f:7e:b8:
                    05:e5:67:e0:cb:9c:f1:28:5f:15:c2:91:14:50:43:
                    3e:49:9f:6d:46:1f:ff:92:0f:f9:3e:80:37:36:36:
                    8c:0c:33:5e:ea:b8:5c:4e:34:c4:2e:69:48:a1:39:
                    62:d7:1d:59:e0:ac:c6:ba:31:9d:31:2c:bd:3b:fc:
                    e6:b1:1b:a4:4f:d8:21:77:52:90:a1:f5:e0:e8:a4:
                    a3:86:cc:4c:de:3c:b1:74:cf:c2:39:49:d7:26:5e:
                    f7:71:55:29:6e:14:da:b8:56:8b:02:59:95:a8:39:
                    a0:e5:c6:35:63:d1:68:7a:0f:2e:44:68:1e:7d:92:
                    0d:d9:53:1d:6b:26:22:12:be:72:cd:b6:81:a7:9c:
                    e8:89:cd:f3:96:6b:58:36:29:99:8d:41:2c:7a:74:
                    da:4f:97:de:7d:b0:e1:8c:be:15:f0:a9:87:73:58:
                    fc:92:a4:5a:32:bd:c1:55:73:a4:ae:67:af:40:bd:
                    00:4b:b4:f4:1b:6d:d6:1a:9b:16:37:a1:78:23:9a:
                    16:ce:85:ce:d4:6d:02:1c:cc:c3:41:f0:c1:97:02:
                    2a:c4:af:8a:de:65:85:0e:a9:1e:18:9e:1e:3d:2a:
                    92:57:de:3e:69:9d:59:c3:0b:66:6e:bb:a2:dd:a1:
                    5d:50:43:cd:9a:e8:46:c4:33:bd:35:b8:d1:30:0e:
                    f2:f7:dc:01:26:f9:bd:65:ac:64:bb:6a:b1:7f:ee:
                    83:1d:20:ee:63:4d:dd:27:3c:50:47:ca:16:11:17:
                    59:6e:72:4d:6f:fd:dd:da:7e:ac:0b:c5:0a:cd:06:
                    25:f9:d1:c6:5d:f1:5d:21:2a:26:64:dc:12:51:a7:
                    7e:1b:bf:d1:aa:c8:72:61:53:37:76:19:1a:41:35:
                    2d:30:07:67:c9:80:82:21:f1:31:49:1e:9a:f5:cd:
                    5f:01:43:d6:5b:77:2e:9e:d4:62:c8:05:3f:82:16:
                    93:01:68:68:76:0e:59:bf:8f:ec:c6:1a:bf:68:be:
                    70:b8:09:e8:e7:46:f4:6f:ae:9c:a5:18:fd:fb:77:
                    0b:92:03:9c:45:a7:ae:2e:dc:57:6c:93:3f:1d:fb:
                    61:8e:60:97:5d:62:19:84:b8:07:02:63:6e:b6:a8:
                    54:7c:73:c4:e0:9e:a4:18:f5:59:42:b5:b9:9c:cf:
                    d3:64:c9:c7:b5:f8:f8:20:79:3f:03:c7:b2:74:64:
                    0f:ba:b7:b5:fe:71:66:b8:ba:4c:d0:e3:86:b1:a6:
                    63:5d:2a:c0:06:d4:c1:eb:d8:23:bf:c9:34:25:b8:
                    b2:69:ab:00:9b:ea:62:f1:10:39:3b:93:5e:d8:4f:
                    73:c3:21
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Key Identifier:
                75:06:74:70:7D:7E:9E:FB:8F:BB:83:E1:29:90:4B:B2:02:0D:F3:9F
            X509v3 Authority Key Identifier:
                75:06:74:70:7D:7E:9E:FB:8F:BB:83:E1:29:90:4B:B2:02:0D:F3:9F
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        7a:00:32:36:c1:8f:70:6c:33:cd:40:a5:be:b0:a2:5d:a3:c6:
        ca:ce:d1:f3:21:72:07:04:a7:23:a9:82:a0:2a:c9:49:28:7d:
        48:0a:17:7a:b3:d1:f9:91:ea:c8:ac:fc:9b:d1:75:46:5d:14:
        ea:33:c8:1a:f4:73:1a:1f:89:e4:44:4a:87:89:7a:9b:aa:fb:
        be:03:30:3b:58:43:0b:1b:a9:38:1c:f7:42:d4:ac:22:4a:84:
        d1:3e:fd:21:62:9b:f7:e2:4e:00:6d:37:14:08:db:65:43:22:
        13:0d:a2:04:97:a1:74:01:fb:b9:a7:9c:f2:bd:f1:f8:47:70:
        d7:33:34:16:80:8c:7f:eb:ba:7b:99:5f:40:8c:ce:47:f2:fd:
        d7:05:00:28:83:a0:9f:59:b7:72:54:a3:8d:fa:1e:3e:56:d9:
        b1:fd:5b:a7:b7:36:95:89:2b:05:d1:44:04:72:8e:df:e6:00:
        68:46:ed:de:8f:a8:eb:ee:0f:5e:d7:5c:31:73:ed:e3:f2:9c:
        2f:fe:19:30:6f:84:9f:c3:e2:93:85:e7:63:3f:55:76:20:82:
        23:93:bb:45:ac:13:ba:d8:e3:53:40:43:03:31:09:eb:2e:3e:
        f2:dd:51:90:4c:53:5a:53:9c:5b:ac:7f:a5:63:ea:43:30:e3:
        b5:7f:c4:63:17:74:9a:47:52:85:54:37:69:b6:84:06:be:9d:
        55:0b:bb:53:f1:3b:c5:a1:75:21:28:6f:86:cf:7b:34:09:6c:
        f7:39:e5:02:da:89:e1:c2:bf:80:bb:9d:21:cf:fd:63:ae:04:
        82:b1:5b:61:ea:e4:0d:a1:37:a2:e6:3a:e9:0b:22:4b:f8:55:
        81:93:91:9a:2b:20:d3:69:38:a8:cf:f5:86:ba:e7:b9:12:19:
        e2:ad:f2:2b:eb:9b:49:3e:4c:9e:a5:7d:ee:8e:f6:50:df:f0:
        0f:fa:36:14:d8:fe:81:1c:0d:ae:6e:41:ea:b2:36:87:b2:88:
        d2:af:83:14:95:82:65:fd:fb:58:42:8f:08:4e:65:4c:00:fd:
        5d:e3:2c:c3:6a:76:0e:7a:2a:e1:00:2f:86:48:c2:ad:aa:4f:
        b7:99:af:4e:7a:d1:b6:29:0e:96:e4:fe:95:7f:2e:0c:e0:a9:
        ec:08:59:ce:9b:f8:b8:92:a4:71:03:b7:08:e0:fc:16:2f:0d:
        1a:4e:ee:50:53:37:b0:e6:81:ea:d6:f0:7a:d8:62:b3:07:7f:
        67:35:ca:71:0b:bc:de:97:91:33:46:71:e5:a5:df:92:3f:2f:
        15:f0:8e:8b:0d:f0:fc:6e:fc:4a:93:6e:9b:d4:cc:83:20:b7:
        26:95:e4:e8:ed:d6:16:b2
```

Необходимо скопировать корневой сертификат на общее хранилище для дальнейшего использования:
```bash
root@96520cbdbfc0:~/ca# cp certs/ca.cert.pem /root/share/
root@96520cbdbfc0:~/ca# chmod 444 /root/share/ca.cert.pem
```

## Настройка промежуточного центра сертификации

Подключение к контейнеру, переход в рабочий каталог:
```bash
root@vm-ubnt:/opt/lab_pki# ssh student@127.0.0.1 -p 22001
The authenticity of host '[127.0.0.1]:22001 ([127.0.0.1]:22001)' can't be established.
ED25519 key fingerprint is SHA256:D5wsCTob8FyPVnWQKyUGGbFsyOrjW+lStBEfJZnqh4E.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:1: [hashed name]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[127.0.0.1]:22001' (ED25519) to the list of known hosts.
student@127.0.0.1's password:
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.8.0-79-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

student@4f12b3aebba1:~$ sudo bash
[sudo] password for student:
root@4f12b3aebba1:/home/student# cd /root/intermediate/
root@4f12b3aebba1:~/intermediate# ls -la
total 40
drwxr-xr-x 7 root root 4096 Oct 15 10:21 .
drwx------ 1 root root 4096 Oct 15 10:08 ..
drwxr-xr-x 2 root root 4096 Oct 15 09:53 certs
drwxr-xr-x 2 root root 4096 Oct 15 09:53 crl
-rw-r--r-- 1 root root    5 Oct 15 10:08 crlnumber
drwxr-xr-x 2 root root 4096 Oct 15 09:53 csr
-rw-r--r-- 1 root root    0 Oct 15 10:08 index.txt
drwxr-xr-x 2 root root 4096 Oct 15 09:53 newcerts
-rw-r--r-- 1 root root 3012 Oct 14 14:53 openssl.cnf
drwx------ 2 root root 4096 Oct 15 09:53 private
-rw-r--r-- 1 root root    5 Oct 15 10:08 serial
```

Генерация ключа для промежуточного сертификата:
```bash
root@4f12b3aebba1:~/intermediate# openssl genrsa -aes256 -out private/intermediate.key.pem 4096
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:


root@4f12b3aebba1:~/intermediate# chmod 400 private/intermediate.key.pem
```

В качестве pass phrase можно использовать произвольную последовательность, например, `123123`.

Генерация csr-запроса и отправка его в общее хранилище:
```bash
root@4f12b3aebba1:~/intermediate# pwd
/root/intermediate
root@4f12b3aebba1:~/intermediate# openssl req -config openssl.cnf -new -sha256 \
-key private/intermediate.key.pem \
-out csr/intermediate.csr.pem
Enter pass phrase for private/intermediate.key.pem:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [RU]:RU
State or Province Name [Moscow]:Moscow
Locality Name [Moscow]:Moscow
Organization Name [LAB]:LAB
Organizational Unit Name [LAB Intermediate CA]:LAB Intermediate CA
Common Name [LAB Intermediate CA]:LAB Intermediate CA
Email Address [subca@lab.local]:subca@lab.local
root@4f12b3aebba1:~/intermediate# cp csr/intermediate.csr.pem /root/share/
root@4f12b3aebba1:~/intermediate# ls -la /root/share
total 12
drwxr-xr-x 2 root root 4096 Oct 16 07:27 .
drwx------ 1 root root 4096 Oct 16 07:20 ..
-rw-r--r-- 1 root root 1765 Oct 16 07:27 intermediate.csr.pem
```

Необходимо подключиться к root-ca:
```bash
root@ac71a74e5eff:/home/student# cd /root/ca
root@ac71a74e5eff:~/ca# ls -la
total 32
drwxr-xr-x 6 root root 4096 Oct 15 10:21 .
drwx------ 1 root root 4096 Oct 16 07:21 ..
drwxr-xr-x 2 root root 4096 Oct 15 10:23 certs
drwxr-xr-x 2 root root 4096 Oct 15 09:51 crl
-rw-r--r-- 1 root root    0 Oct 16 07:20 index.txt
drwxr-xr-x 2 root root 4096 Oct 15 09:51 newcerts
-rw-r--r-- 1 root root 2299 Oct 14 14:53 openssl.cnf
drwx------ 2 root root 4096 Oct 15 10:16 private
-rw-r--r-- 1 root root    5 Oct 16 07:20 serial
root@ac71a74e5eff:~/ca# openssl ca -config openssl.cnf -extensions v3_intermediate_ca -days 3650 -notext -md sha256 -in /root/share/intermediate.csr.pem -out /root/share/intermediate.cert.pem
Using configuration from openssl.cnf
Enter pass phrase for /root/ca/private/ca.key.pem:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4096 (0x1000)
        Validity
            Not Before: Oct 16 07:28:26 2025 GMT
            Not After : Oct 14 07:28:26 2035 GMT
        Subject:
            countryName               = RU
            stateOrProvinceName       = Moscow
            organizationName          = LAB
            organizationalUnitName    = LAB Intermediate CA
            commonName                = LAB Intermediate CA
            emailAddress              = subca@lab.local
        X509v3 extensions:
            X509v3 Subject Key Identifier:
                D8:11:D9:1D:C7:A1:79:C9:4B:CA:74:2B:30:CF:58:39:A3:B1:5A:51
            X509v3 Authority Key Identifier:
                75:06:74:70:7D:7E:9E:FB:8F:BB:83:E1:29:90:4B:B2:02:0D:F3:9F
            X509v3 Basic Constraints: critical
                CA:TRUE, pathlen:0
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
Certificate is to be certified until Oct 14 07:28:26 2035 GMT (3650 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Database updated

root@ac71a74e5eff:~/ca# chmod 444 /root/share/intermediate.cert.pem

root@ac71a74e5eff:~/ca# cat index.txt
V       351014072826Z           1000    unknown /C=RU/ST=Moscow/O=LAB/OU=LAB Intermediate CA/CN=LAB Intermediate CA/emailAddress=subca@lab.local

root@ac71a74e5eff:~/ca# openssl x509 -noout -text \
-in /root/share/intermediate.cert.pem
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 4096 (0x1000)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = RU, ST = Moscow, L = Moscow, O = LAB, OU = LAB Root CA, CN = LAB Root CA, emailAddress = rootca@lab.local
        Validity
            Not Before: Oct 16 07:28:26 2025 GMT
            Not After : Oct 14 07:28:26 2035 GMT
        Subject: C = RU, ST = Moscow, O = LAB, OU = LAB Intermediate CA, CN = LAB Intermediate CA, emailAddress = subca@lab.local
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (4096 bit)
                Modulus:
                    00:8f:8b:59:9a:01:a7:4c:47:60:07:6a:5e:7b:6c:
                    e2:94:1f:56:b8:2d:e5:f8:74:77:91:8a:92:2c:e0:
                    45:93:fe:d7:fc:5c:d5:73:1a:14:58:07:8e:1b:a1:
                    a0:f7:e2:69:a4:4a:c1:7d:92:da:63:58:b4:e1:11:
                    ec:c4:b6:33:54:8f:ec:77:ef:89:aa:37:4e:e3:8a:
                    53:97:0f:4a:fe:32:b1:ee:2d:78:ea:78:d6:33:9c:
                    19:72:5f:09:c4:f7:6a:52:f0:49:56:4f:d5:3a:5f:
                    0d:ea:bb:42:c0:bc:b8:a6:de:86:29:50:d4:36:93:
                    97:65:e1:eb:45:ea:ff:14:ef:a3:f5:be:ad:5f:b4:
                    dc:aa:f8:6f:b2:50:34:19:70:61:62:8d:0f:26:b6:
                    08:18:05:97:ba:6c:ac:54:5a:6b:10:ab:b1:7f:b6:
                    82:04:05:93:7c:67:43:6a:48:2f:b2:7f:be:82:fd:
                    82:d2:c4:bb:aa:62:e0:1d:b8:3b:21:35:fb:e7:17:
                    de:19:f4:c4:61:8a:7a:f3:0d:82:5b:08:fc:32:ff:
                    3b:fb:8c:5d:a7:cc:90:fd:ab:91:39:9c:ba:ba:ff:
                    4e:86:09:80:e4:4e:d1:ee:0e:b0:01:49:c6:d3:de:
                    d9:69:80:09:d7:c9:f2:24:85:b0:0d:59:a8:a6:f2:
                    07:ed:ac:c3:1e:9e:f7:23:bd:6f:9b:c6:e0:0b:fd:
                    54:5b:b2:e7:4c:64:ad:88:a9:85:c4:5d:30:08:be:
                    94:bb:8f:0f:c1:93:94:96:96:9b:9f:30:dc:75:41:
                    e0:70:dc:46:4f:3d:47:22:c8:3d:90:73:f8:a8:93:
                    ec:ac:02:d2:b6:a2:37:aa:92:2e:4e:53:30:58:56:
                    3d:f7:cc:ca:34:eb:cd:85:cf:d5:a0:5e:41:31:a2:
                    c1:06:39:a3:69:40:42:e3:82:35:af:5b:7f:53:2b:
                    f8:f8:bd:1c:98:3b:75:5e:0f:bf:7e:b8:14:cf:34:
                    30:2f:63:7a:71:db:13:cb:2a:3f:9d:e3:85:65:19:
                    67:0b:cc:1b:7f:4d:09:43:86:59:83:b6:6f:6c:ab:
                    9f:50:22:12:6d:5d:55:57:2e:02:10:01:21:cc:5b:
                    08:36:9c:d0:26:2e:79:28:78:f5:36:35:c0:47:6f:
                    be:83:4a:9e:50:77:31:5a:7a:d1:99:3f:e1:9a:a7:
                    79:98:c2:e4:97:df:f5:cd:d4:27:38:75:55:99:4c:
                    90:55:91:05:97:ef:5b:4b:dc:98:f3:b4:0b:2b:c1:
                    23:09:cc:4e:55:8b:cd:1d:43:0f:92:49:85:49:fe:
                    0f:84:22:52:28:05:d7:c0:ab:76:c4:5e:e1:e0:23:
                    74:67:31
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Key Identifier:
                D8:11:D9:1D:C7:A1:79:C9:4B:CA:74:2B:30:CF:58:39:A3:B1:5A:51
            X509v3 Authority Key Identifier:
                75:06:74:70:7D:7E:9E:FB:8F:BB:83:E1:29:90:4B:B2:02:0D:F3:9F
            X509v3 Basic Constraints: critical
                CA:TRUE, pathlen:0
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        6b:ad:5f:23:59:75:a6:d0:a8:c5:39:87:03:c4:37:d1:6f:56:
        c4:4a:7c:b5:c0:e3:a2:47:37:f3:62:a8:ec:c7:df:4f:7a:34:
        d0:00:17:dc:96:cc:02:20:df:5e:e4:cd:75:d1:0b:93:7f:25:
        83:28:b8:4d:cd:ee:8d:5f:10:bc:6e:06:e6:33:e6:3e:dc:3c:
        2c:ca:c8:6b:38:d6:e8:16:01:d7:ac:b9:dd:28:e3:3c:a9:f5:
        42:55:a3:0d:23:b3:4a:8e:c6:d8:f5:db:3f:eb:9f:f1:d6:55:
        c0:bc:ba:e5:14:6a:b9:4e:f3:c2:4e:a7:6a:48:10:e3:2c:88:
        d7:c5:1a:2d:f4:8a:64:ad:ce:50:6d:96:4f:e4:37:e9:7c:52:
        d8:8a:9d:e8:98:aa:fa:b9:2b:16:1b:69:7f:96:cc:83:52:38:
        9f:8b:55:8b:4b:8c:81:62:a4:a6:57:cf:6e:38:c2:19:7f:59:
        db:a0:7d:21:64:cb:e9:52:96:ce:0a:79:d3:60:ad:38:7e:2b:
        47:fd:57:5c:1e:10:56:2f:1d:82:cd:47:23:53:0f:53:d3:b5:
        55:fd:38:05:86:7a:4d:09:a7:f1:4a:1d:82:48:1f:2a:36:3e:
        f5:e2:d9:09:72:7a:13:ae:40:e9:ac:7d:ff:54:ef:0f:6c:01:
        1a:01:b0:16:ab:17:88:b7:36:45:f7:27:ae:05:15:6f:52:c2:
        25:3e:e3:08:09:0f:72:fb:52:8c:53:e3:66:4c:92:5a:70:ff:
        92:6f:06:74:86:72:eb:ca:59:85:41:6e:a9:8d:d0:59:e1:71:
        7e:4f:b6:6d:e0:2e:78:f5:21:e0:0a:2a:21:ab:f9:6f:8b:9c:
        06:e5:5d:19:24:8e:3f:27:23:44:1d:c2:c6:99:c6:13:4c:fc:
        26:53:c4:e1:91:48:e5:d2:5e:65:f3:82:20:90:84:d9:cf:ec:
        06:20:3f:8c:ef:f3:1e:de:ff:6e:65:d8:99:70:fa:16:8a:fb:
        d7:e5:38:fe:e5:50:03:45:ce:ff:49:26:07:57:74:85:f5:0b:
        5d:24:76:bd:0f:f9:b6:35:98:2b:da:79:e1:7f:c0:98:ce:1b:
        ea:94:15:1c:69:83:1d:01:79:3e:60:75:0a:9d:aa:de:a3:0c:
        70:5b:66:3b:d4:1e:a0:1c:2c:20:66:72:8e:e1:88:1e:35:6f:
        ff:1c:39:7a:7b:b5:12:9b:d8:77:da:08:18:01:17:44:72:c9:
        81:70:38:42:93:01:22:63:04:96:84:a2:a3:be:e7:e1:73:e6:
        10:89:7b:44:e8:11:6d:25:ee:11:7c:cb:f7:d5:fc:fd:d6:e9:
        89:c1:c4:3c:94:42:1e:04
```

На Intermediate-CA:
```bash
root@cafc7c90d92f:~/intermediate# cp /root/share/intermediate.cert.pem /root/intermediate/certs/
```

Проверка 
```bash
root@ac71a74e5eff:~/ca# openssl verify -CAfile /root/share/ca.cert.pem \
/root/share/intermediate.cert.pem
/root/share/intermediate.cert.pem: OK
```

Подготовка certificate-chain:
```bash
root@ac71a74e5eff:~/ca# cat /root/share/intermediate.cert.pem \
/root/share/ca.cert.pem >/root/share/ca-chain.cert.pem
root@ac71a74e5eff:~/ca# chmod 444 /root/share/ca-chain.cert.pem
```

Генерация ключа:
```bash
root@aa912f47dfef:~/intermediate# cd /root/intermediate
openssl genrsa -aes256 \
-out private/nginx.lab.local.key.pem 2048
chmod 400 private/nginx.lab.local.key.pem
Enter PEM pass phrase:
Verifying - Enter PEM pass phrase:
```

Генерация CSR-запроса:
```bash
root@aa912f47dfef:~/intermediate# openssl req -config openssl.cnf \
-key private/nginx.lab.local.key.pem \
-new -sha256 -out csr/nginx.lab.local.csr.pem
Enter pass phrase for private/nginx.lab.local.key.pem:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [RU]:RU
State or Province Name [Moscow]:Moscow
Locality Name [Moscow]:Moscow
Organization Name [LAB]:LAB
Organizational Unit Name [LAB Intermediate CA]:LAB
Common Name [LAB Intermediate CA]:nginx.lab.local
Email Address [subca@lab.local]:nginx@lab.local
```

Выпуск сертификата на сервер:
```bash
root@aa912f47dfef:~/intermediate# openssl ca -config openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in csr/nginx.lab.local.csr.pem -out certs/nginx.lab.local.cert.pem
Using configuration from openssl.cnf
Enter pass phrase for /root/intermediate/private/intermediate.key.pem:
Check that the request matches the signature
Signature ok
Certificate Details:
        Serial Number: 4096 (0x1000)
        Validity
            Not Before: Oct 16 11:21:15 2025 GMT
            Not After : Oct 26 11:21:15 2026 GMT
        Subject:
            countryName               = RU
            stateOrProvinceName       = Moscow
            localityName              = Moscow
            organizationName          = LAB
            organizationalUnitName    = LAB
            commonName                = nginx.lab.local
            emailAddress              = nginx@lab.local
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Cert Type:
                SSL Server
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Key Identifier:
                91:C0:BB:F9:C0:5E:37:0F:7F:7A:69:9D:FF:D9:6F:63:C3:EE:47:98
            X509v3 Authority Key Identifier:
                D8:11:D9:1D:C7:A1:79:C9:4B:CA:74:2B:30:CF:58:39:A3:B1:5A:51
            X509v3 Subject Alternative Name:
                DNS:localhost, DNS:www.lab.local, IP Address:127.0.0.1
            X509v3 CRL Distribution Points:
                Full Name:
                  URI:http://ocsp:8080/intermediate.crl.pem
            Authority Information Access:
                OCSP - URI:http://ocsp:2560
Certificate is to be certified until Oct 26 11:21:15 2026 GMT (375 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Database updated
```

Права:
```bash
chmod 444 certs/nginx.lab.local.cert.pem
```

Копирование сертификата и ключа на nginx:
```bash
root@f587580a50bf:~/intermediate# mv /root/nginx_share/certs/nginx.lab.local.cert.pem /root/nginx_share/certs/nginx.lab.local.cert.pem_old_$(date +%F)
root@f587580a50bf:~/intermediate# mv /root/nginx_share/private/nginx.lab.local.key.pem /root/nginx_share/private/nginx.lab.local.key.pem_old_$(date +%F)
root@aa912f47dfef:~/nginx_share# cat /root/intermediate/certs/nginx.lab.local.cert.pem \
/root/share/ca-chain.cert.pem > /root/nginx_share/certs/nginx.lab.local.cert.pem
root@aa912f47dfef:~/nginx_share# chmod 444 /root/nginx_share/certs/nginx.lab.local.cert.pem
root@aa912f47dfef:~/intermediate# cp private/nginx.lab.local.key.pem /root/nginx_share/private/
root@aa912f47dfef:~/nginx_share# chmod 400 /root/nginx_share/private/nginx.lab.local.key.pem 
```

Проверка:
```bash
openssl s_client -connect 127.0.0.1:8443
```

Необходимо убрать защиту pem-паролем для ключа:
```bash
root@f587580a50bf:~/intermediate# cd /root/nginx_share/private/
root@f587580a50bf:~/nginx_share/private# openssl rsa -in nginx.lab.local.key.pem -out nginx.lab.local.key.nopass.pem
mv nginx.lab.local.key.nopass.pem nginx.lab.local.key.pem
chmod 400 nginx.lab.local.key.pem
Enter pass phrase for nginx.lab.local.key.pem:
writing RSA key
```

Перезапустить только контейнер nginx:
```bash
root@vm-ubnt:/opt/lab_pki# docker compose stop nginx-server
[+] Stopping 1/1
 ✔ Container lab_pki-nginx-server-1  Stopped                                                                                                                                                                  0.7s
root@vm-ubnt:/opt/lab_pki# docker compose start nginx-server
[+] Running 1/1
 ✔ Container lab_pki-nginx-server-1  Started                                                                                                                                                                  1.6s
```

## Конфигурация CRL

На Intermediate-CA:
```bash
root@cafc7c90d92f:~/intermediate# openssl ca -config openssl.cnf -gencrl -out crl/intermediate.crl.pem
Using configuration from openssl.cnf
Enter pass phrase for /root/intermediate/private/intermediate.key.pem:
root@cafc7c90d92f:~/intermediate# cp crl/intermediate.crl.pem /root/share/
```


