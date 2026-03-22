unit hazario;

interface

uses
  SysUtils, Classes, hazar;

function EncryptFile(const InputFile, OutputFile, Password: string): Boolean;
function DecryptFile(const InputFile, OutputFile, Password: string): Boolean;

implementation

const
  VERIFY_SIZE = 256;
  BLOCK_SIZE = 256;
  SIZE_FIELD_BYTES = 8;

procedure PasswordToKey(const Password: string; out Key: THazarData; out KeyLength: THazarInteger);
var
  I: Integer;
begin
  FillChar(Key, SizeOf(Key), 0);
  if Length(Password) = 0 then
  begin
    KeyLength := 0;
    Exit;
  end;
  KeyLength := THazarInteger(Length(Password) mod N);
  for I := 1 to Length(Password) do
    Key[THazarInteger((I - 1) mod N)] := Key[THazarInteger((I - 1) mod N)] xor THazarInteger(Ord(Password[I]));
end;

function EncryptFile(const InputFile, OutputFile, Password: string): Boolean;
var
  OrigSize: Int64;
  I, BytesRead: Integer;
  Cipher: THazarEncryption;
  KeyLength: THazarInteger;
  Key, KeyStream: THazarData;
  InStream, OutStream: TFileStream;
  Buffer: array [0 .. BLOCK_SIZE - 1] of byte;
  EncSize: array [0 .. SIZE_FIELD_BYTES - 1] of byte;
  SizeBytes: array [0 .. SIZE_FIELD_BYTES - 1] of byte absolute OrigSize;
begin
  Result := False;
  PasswordToKey(Password, Key, KeyLength);
  Cipher := THazarEncryption.Initialize(Key, KeyLength);
  try
    InStream := TFileStream.Create(InputFile, fmOpenRead or fmShareDenyWrite);
    try
      OutStream := TFileStream.Create(OutputFile, fmCreate);
      try
        KeyStream := Cipher.GenerateKey;
        OutStream.WriteBuffer(KeyStream, VERIFY_SIZE);
        OrigSize := InStream.Size;
        KeyStream := Cipher.GenerateKey;
        for I := 0 to SIZE_FIELD_BYTES - 1 do
          EncSize[I] := SizeBytes[I] xor KeyStream[I];
        OutStream.WriteBuffer(EncSize, SIZE_FIELD_BYTES);
        repeat
          FillChar(Buffer, BLOCK_SIZE, 0);
          BytesRead := InStream.Read(Buffer, BLOCK_SIZE);
          if BytesRead > 0 then
          begin
            KeyStream := Cipher.GenerateKey;
            for I := 0 to BLOCK_SIZE - 1 do
              Buffer[I] := Buffer[I] xor KeyStream[I];
            OutStream.WriteBuffer(Buffer, BLOCK_SIZE);
          end;
        until BytesRead < BLOCK_SIZE;
        Result := True;
      finally
        OutStream.Free;
        if not Result then
          SysUtils.DeleteFile(OutputFile);
      end;
    finally
      InStream.Free;
    end;
  finally
    Cipher.Free;
  end;
end;

function DecryptFile(const InputFile, OutputFile, Password: string): Boolean;
var
  OrigSize: Int64;
  IsValid: Boolean;
  I, BytesRead: Integer;
  Cipher: THazarEncryption;
  KeyLength: THazarInteger;
  Key, KeyStream: THazarData;
  InStream, OutStream: TFileStream;
  VerifyBlock: array [0 .. VERIFY_SIZE - 1] of byte;
  Buffer: array [0 .. BLOCK_SIZE - 1] of byte;
  SizeBytes: array [0 .. SIZE_FIELD_BYTES - 1] of byte absolute OrigSize;
  EncSize: array [0 .. SIZE_FIELD_BYTES - 1] of byte;
begin
  Result := False;
  PasswordToKey(Password, Key, KeyLength);
  Cipher := THazarEncryption.Initialize(Key, KeyLength);
  try
    InStream := TFileStream.Create(InputFile, fmOpenRead or fmShareDenyWrite);
    try
      if InStream.Read(VerifyBlock, VERIFY_SIZE) < VERIFY_SIZE then
        Exit;
      KeyStream := Cipher.GenerateKey;
      IsValid := True;
      for I := 0 to VERIFY_SIZE - 1 do
        if (VerifyBlock[I] xor KeyStream[I]) <> $00 then
        begin
          IsValid := False;
          Break;
        end;
      if not IsValid then
        Exit;
      if InStream.Read(EncSize, SIZE_FIELD_BYTES) < SIZE_FIELD_BYTES then
        Exit;
      KeyStream := Cipher.GenerateKey;
      for I := 0 to SIZE_FIELD_BYTES - 1 do
        SizeBytes[I] := EncSize[I] xor KeyStream[I];
      if (OrigSize < 0) or (OrigSize > InStream.Size - InStream.Position) then
        Exit;
      OutStream := TFileStream.Create(OutputFile, fmCreate);
      try
        repeat
          BytesRead := InStream.Read(Buffer, BLOCK_SIZE);
          if BytesRead > 0 then
          begin
            KeyStream := Cipher.GenerateKey;
            for I := 0 to BLOCK_SIZE - 1 do
              Buffer[I] := Buffer[I] xor KeyStream[I];
            OutStream.WriteBuffer(Buffer, BLOCK_SIZE);
          end;
        until BytesRead < BLOCK_SIZE;
        OutStream.Size := OrigSize;
        Result := True;
      finally
        OutStream.Free;
        if not Result then
          SysUtils.DeleteFile(OutputFile);
      end;
    finally
      InStream.Free;
    end;
  finally
    Cipher.Free;
  end;
end;

end.
