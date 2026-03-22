unit hazardel;

interface

uses
  SysUtils, Classes, hazar;

function SecureDelete(const FileName: string; Rounds: Integer = 1): boolean;

implementation

const
  BLOCK_SIZE = 256;
  SECONDS_PER_DAY = 86400;

function DateTimeToSeconds(DT: TDateTime): Int64;
begin
  Result := Trunc(DT * SECONDS_PER_DAY);
end;

procedure BuildSeedKey(Seconds: Int64; out Key: THazarData; out KLen: THazarInteger);
type
  TInt64Bytes = array [0..7] of byte;
var
  I: Integer;
  B: TInt64Bytes absolute Seconds;
begin
  FillChar(Key, SizeOf(Key), 0);
  for I := 0 to 7 do
    Key[THazarInteger(I)] := Key[THazarInteger(I)] xor B[I];
  KLen := THazarInteger(B[0]);
end;

procedure WipeRound(Stream: TFileStream; FileSize: Int64);
var
  KLen: THazarInteger;
  I, ChunkSize: Integer;
  Cipher: THazarEncryption;
  Remaining, Seconds: Int64;
  Key, KeyStream: THazarData;
  Buffer, InvBuffer: array [0 .. BLOCK_SIZE - 1] of byte;
begin
  Seconds := DateTimeToSeconds(Now);
  BuildSeedKey(Seconds, Key, KLen);
  Cipher := THazarEncryption.Initialize(Key, KLen);
  try
    Stream.Seek(0, soBeginning);
    Remaining := FileSize;
    while Remaining > 0 do
    begin
      if Remaining >= BLOCK_SIZE then
        ChunkSize := BLOCK_SIZE
      else ChunkSize := Integer(Remaining);
      KeyStream := Cipher.GenerateKey;
      for I := 0 to ChunkSize - 1 do
        Buffer[I] := KeyStream[I];
      Stream.WriteBuffer(Buffer, ChunkSize);
      Dec(Remaining, ChunkSize);
    end;
    FreeAndNil(Cipher);
    BuildSeedKey(Seconds, Key, KLen);
    Cipher := THazarEncryption.Initialize(Key, KLen);
    Stream.Seek(0, soBeginning);
    Remaining := FileSize;
    while Remaining > 0 do
    begin
      if Remaining >= BLOCK_SIZE then
        ChunkSize := BLOCK_SIZE
      else ChunkSize := Integer(Remaining);
      KeyStream := Cipher.GenerateKey;
      for I := 0 to ChunkSize - 1 do
        InvBuffer[I] := not KeyStream[I];
      Stream.WriteBuffer(InvBuffer, ChunkSize);
      Dec(Remaining, ChunkSize);
    end;
  finally
    Cipher.Free;
  end;
end;

function SecureDelete(const FileName: string; Rounds: Integer = 1): boolean;
var
  FileSize: Int64;
  I, Round: Integer;
  Stream: TFileStream;
  Dir, TempName, RandSuffix: string;
begin
  Result := False;
  if not FileExists(FileName) then
    Exit;
  if Rounds < 1 then
    Rounds := 1;
  Stream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareExclusive);
  try
    FileSize := Stream.Size;
    if FileSize > 0 then
    begin
      for Round := 1 to Rounds do
        WipeRound(Stream, FileSize);
    end;
    Stream.Size := 0;
  finally
    Stream.Free;
  end;
  Dir := ExtractFilePath(FileName);
  RandSuffix := '';
  Randomize;
  for I := 1 to 8 do
    RandSuffix := RandSuffix + IntToHex(Random(256), 2);
  TempName := Dir + RandSuffix + '.tmp';
  if RenameFile(FileName, TempName) then
    Result := SysUtils.DeleteFile(TempName)
  else Result := SysUtils.DeleteFile(FileName);
end;

end.
