unit hazarcipher;

{
  HazarCipher — Stream Cipher Encryption/Decryption Unit
  -------------------------------------------------------
  Uses the Hazar key scheduler (hazar.pas) as a keystream generator.

  How it works:
    - THazarEncryption.GenerateKey produces a fresh 256-byte (hazar8) or
      65536-word (hazar16) keystream block on every call.
    - Plaintext/ciphertext is split into N-byte blocks; each block is XOR'd
      with one generated keystream block.
    - Because XOR is its own inverse, Encrypt and Decrypt are the same
      operation.  Both are exposed separately for clarity.

  Usage example:
    var
      Cipher : THazarCipher;
      Key    : THazarData;
      Data   : array of Byte;
      Len    : Integer;
    begin
      // Fill Key and Len however you like, e.g. from a passphrase hash.
      Cipher := THazarCipher.Create(Key, Len);
      try
        Cipher.Encrypt(Data, Length(Data));   // in-place encryption
        // ... transmit Data ...
        Cipher.Free;

        Cipher := THazarCipher.Create(Key, Len);  // same key, fresh state
        Cipher.Decrypt(Data, Length(Data));   // in-place decryption
      finally
        Cipher.Free;
      end;
    end;

  IMPORTANT — One-time key semantics:
    Each THazarCipher instance must be used for ONE message only.
    Re-using the same key+instance for two different messages breaks
    stream-cipher security (crib-dragging / two-time-pad attack).
    Always create a fresh instance (or include a unique nonce in the key)
    for every new message.
}

interface

uses
  hazar;

type
  THazarCipher = class
  private
    FEngine: THazarEncryption;
    { Core XOR routine shared by Encrypt and Decrypt }
    procedure Process(var Data: array of Byte; DataLen: Integer);
  public
    { Key      : initial key data (THazarData array)
      KeyLength: number of meaningful key bytes / key-strength hint }
    constructor Create(Key: THazarData; KeyLength: THazarInteger);
    destructor  Destroy; override;

    { Encrypt DataLen bytes of Data in-place.
      Advances the internal keystream — do NOT call again on the same
      instance unless you intend to continue the same stream. }
    procedure Encrypt(var Data: array of Byte; DataLen: Integer);

    { Decrypt DataLen bytes of Data in-place.
      Internally identical to Encrypt; provided separately for readability. }
    procedure Decrypt(var Data: array of Byte; DataLen: Integer);
  end;

implementation

{ THazarCipher }

constructor THazarCipher.Create(Key: THazarData; KeyLength: THazarInteger);
begin
  inherited Create;
  FEngine := THazarEncryption.Initialize(Key, KeyLength);
end;

destructor THazarCipher.Destroy;
begin
  FEngine.Free;
  inherited Destroy;
end;

procedure THazarCipher.Process(var Data: array of Byte; DataLen: Integer);
var
  KeyStream  : THazarData;      { one freshly generated keystream block  }
  BlockStart : Integer;         { byte index of the current block        }
  BlockBytes : Integer;         { bytes consumed from this keystream block }
  ByteIdx    : Integer;         { index within the current block         }
begin
  { Validate caller did not pass a length larger than the actual array. }
  if DataLen > Length(Data) then
    DataLen := Length(Data);

  BlockStart := 0;

  while BlockStart < DataLen do
  begin
    { Generate the next keystream block (N bytes = 256 in hazar8 mode). }
    KeyStream := FEngine.GenerateKey;

    { How many data bytes does this block cover?
      Last block may be smaller than N. }
    BlockBytes := DataLen - BlockStart;
    if BlockBytes > N then
      BlockBytes := N;

    { XOR each data byte with the corresponding keystream byte. }
    for ByteIdx := 0 to BlockBytes - 1 do
      Data[BlockStart + ByteIdx] :=
        Data[BlockStart + ByteIdx] xor KeyStream[ByteIdx];

    Inc(BlockStart, BlockBytes);
  end;
end;

procedure THazarCipher.Encrypt(var Data: array of Byte; DataLen: Integer);
begin
  Process(Data, DataLen);
end;

procedure THazarCipher.Decrypt(var Data: array of Byte; DataLen: Integer);
begin
  { XOR-stream decryption is identical to encryption. }
  Process(Data, DataLen);
end;

end.
