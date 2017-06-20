import base64
import struct
from hashlib import sha256
from Crypto.Cipher import AES


MAGIC = '::::MAGIC::::'
PAD_BLOCK_LEN = 16
KEY_LEN = 16


def jenkins_encrypt(value, master_key, secret_key_base64):
    ''' filter to encrypt values that we insert into xml config files '''
    # if we're passed dicts from a shell command, get the stdouts
    if type(master_key) == dict:
        master_key = master_key['stdout']
    if type(secret_key_base64) == dict:
        secret_key_base64 = secret_key_base64['stdout']
    # get the hash of the master key, then throw away half of it
    # because woo yay java encryption export restrictions
    hashed_master_key = sha256(master_key).digest()[:KEY_LEN]
    # get the raw encrypted secret key. It's base64 to begin
    # with because we read it from the host through a shell command
    secret_key_encrypted = base64.decodestring(secret_key_base64)
    # decrypt the secret key
    cipher = AES.new(hashed_master_key, AES.MODE_ECB)
    secret_key_full = cipher.decrypt(secret_key_encrypted)
    # make sure we have a valid secret key by checking the jenkins
    # magic token is in there, and hard fail if we don't
    assert MAGIC in secret_key_full
    # remove the magic token and padding
    secret_key = secret_key_full[:-KEY_LEN]
    # and truncacte because woo yay java again
    secret_key = secret_key[:KEY_LEN]
    # now we have all the keys in the right forms, we need to add
    # the magic token to the value we want to encrypt and pad it
    # for pkcs7 compliance
    stored_value = value + MAGIC
    pad_len = PAD_BLOCK_LEN - (len(stored_value) % PAD_BLOCK_LEN)
    stored_value = stored_value + struct.pack('B', pad_len) * pad_len
    # finally, encrypt with the secret key and return a base64 encoded
    # version of the encrypted value
    cipher = AES.new(secret_key, AES.MODE_ECB)
    encrypted_value = cipher.encrypt(stored_value)
    return base64.encodestring(encrypted_value).strip()


class FilterModule(object):
    ''' jenkins utility filters '''

    def filters(self):
        return {
            'jenkins_encrypt': jenkins_encrypt,
        }
