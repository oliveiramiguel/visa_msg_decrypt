###
  Algo:
    1. Base64-decode the encrypted dynamic key
    2. Remove the first 32 bytes of the decoded value–this is the HMAC. Calculate a SHA-256 HMAC of the rest of the decoded data using your shared secret and compare it with the HMAC from the first 32 bytes.
    3. The next 16 bytes should be removed and used as the IV for the decryption algorithm
    4. Decrypt the remaining data using AES-256-CBC, the IV from Step 1c, and the SHA-256 hash of the shared secret.

    Now, Decrypt the payment data payload (encPaymentData) using the decrypted dynamic key from Step 4
    5. Base64-decode the encrypted payment data
    6. Remove the first 32 bytes of the decoded value–this is the HMAC.  Calculate a SHA-256 HMAC of the rest of the decoded data using your decrypted dynamic key and compare it with the HMAC from the first 32 bytes.
    7. The next 16 bytes should be removed and used as the IV for the decryption algorithm.
    8. Decrypt the rest of the payload using AES-256-CBC, the IV from Step 2c, and the SHA-256 hash of the decrypted dynamic key.

  Author: Rajat Kumar
###

fs = require('fs')
crypto = require('crypto')

class VisaPayloadDecrypt
  constructor:(@secret, @enableLogs = false) ->

  decrypt: (encKey, encPaymentData) ->
    dynamicSecretKey = @_decryptData(@secret, encKey)
    paymentData = @_decryptData(dynamicSecretKey, encPaymentData)
    return JSON.parse paymentData

  _decryptData: (key, payload) ->
    buffer = new Buffer(payload, 'base64')
    hmac = buffer.slice(0, 32).toString('base64')
    iv = buffer.slice(32, 48)
    payloadContent = buffer.slice(48)
    dataToCalculateHmac = buffer.slice(32)

    key = new Buffer(key, 'binary')
    resultHmac = crypto.createHmac('sha256', key).update(dataToCalculateHmac).digest('base64')

    if @enableLogs then console.log 'HMAC:' + hmac
    if @enableLogs then console.log 'Generated HMAC:' + resultHmac

    if hmac != resultHmac
      throw new Error('Invalid payload or key. HMAC verification failed.')

    if @enableLogs then console.log 'HMAC verification successfull'
    shaKey = crypto.createHash('sha256').update(key, 'binary').digest()
    decryptor = crypto.createDecipheriv('aes-256-cbc', shaKey, iv)
    decryptedText = decryptor.update(payloadContent, 'binary', 'binary') + decryptor.final('binary')
    return decryptedText


module.exports = VisaPayloadDecrypt

