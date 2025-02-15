unit hazarh; { Hash algorithm based on Hazar algorithm(variant) }

interface

uses
  hazar, classes, sysutils;

type

  { THazarH }

  THazarH = class(THazar) { This algorithm depends on Hazar8 or Hazar16 while build. }
    private               { HAZAR8 or HAZAR16 compiler directives must be defined at }
      FHash: THazarData;  { main hazar.pas unit.                                     }
    public
      constructor Start(Seed: THazarData; Length: THazarInteger);
      function Feed(Seed: THazarData): THazarData;
  end;

  { THazarHFile }

  THazarHFile = class
    private
      FHashEngine: THazarH;
      FFileReader: TFileStream;
      FFilePath: shortstring;
      FHash: THazarData;
    public
      constructor StartWithFile(FilePath: shortstring);
      function GetFileHash(): THazarData;
  end;

implementation

{ THazarH }

constructor THazarH.Start(Seed: THazarData; Length: THazarInteger);
var
  I: THazarInteger;
begin
  inherited Initialize(Seed, Length);
  for I := $00 to Length do
    FHash[I] := I;
end;

function THazarH.Feed(Seed: THazarData): THazarData;
var
  I: THazarInteger;
begin
  for I := $00 to High(Seed) do
    FHash[I] := FHash[I] xor Seed[I];
  ApplyOTP(FHash);
  Result := FHash;
end;

{ THazarHFile }

constructor THazarHFile.StartWithFile(FilePath: shortstring);
begin
  inherited Create();
  FFilePath := FilePath;
  FFileReader := TFileStream.Create(FFilePath, fmOpenRead);
end;

function THazarHFile.GetFileHash(): THazarData;
var
  Buf, Res: THazarData;
  ReadBytes: Integer;
  SizeOfFileInBytes, RemainingBytes: Int64;
begin
  ReadBytes := $00;
  FillChar(Buf, SizeOf(Buf), $00);
  FillChar(FHash, SizeOf(FHash), $00);
  FHashEngine := THazarH.Start(Buf, hazar.DataMax);
  SizeOfFileInBytes := FFileReader.Size;
  RemainingBytes := SizeOfFileInBytes;
  while RemainingBytes > $00 do
  begin
    ReadBytes := FFileReader.Read(Buf, SizeOf(Buf));
    if ReadBytes > $00 then
    begin
      Res := FHashEngine.Feed(Buf);
      FillChar(Buf, SizeOf(Buf), $00);
      RemainingBytes := RemainingBytes - ReadBytes;
    end;
  end;
  FFileReader.Free();
  Result := Res;
end;

end.
