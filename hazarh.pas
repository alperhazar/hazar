unit hazarh;

interface

uses
  classes, sysutils, tuz;

type

  THazarHFile = class
    private
      FHashEngine: TTuz;
      FFileReader: TFileStream;
      FFilePath: shortstring;
      FHash: TTuzData;
    public
      constructor StartWithFile(FilePath: shortstring);
      function GetFileHash(): TTuzData;
  end;

implementation

constructor THazarHFile.StartWithFile(FilePath: shortstring);
begin
  inherited Create();
  FFilePath := FilePath;
  FFileReader := TFileStream.Create(FFilePath, fmOpenRead);
end;

function THazarHFile.GetFileHash: TTuzData;
var
  Buf: TTuzData;
  ReadBytes: Integer;
  SizeOfFileInBytes, RemainingBytes: Int64;
begin
  ReadBytes := $00;
  FillChar(Buf, SizeOf(Buf), $00);
  FillChar(FHash, SizeOf(FHash), $00);
  FHashEngine := TTuz.Init();
  SizeOfFileInBytes := FFileReader.Size;
  RemainingBytes := SizeOfFileInBytes;
  while RemainingBytes > $00 do
  begin
    ReadBytes := FFileReader.Read(Buf, SizeOf(Buf));
    if ReadBytes > $00 then
    begin
      FHashEngine.Feed(Buf, ReadBytes);
      RemainingBytes := RemainingBytes - ReadBytes;
    end;
  end;
  FFileReader.Free();
  Result := FHashEngine.GetTuzHash();
  FHashEngine.Free();
end;

end.
