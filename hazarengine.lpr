program hazarengine;

uses
  sysutils, Classes, hazar, tuz, hazarh;

const
  OE = 'E';
  OD = 'D';
  OH = 'H';
  MinParamCount = $02;
  MaxParamCount = $04;

type
  RHazarEncryptedFileHeader = record
    FileHash: THazarData;
    FileLength: Int64;
  end;

var
  I, ReadBytes: Integer;
  HazarOperator: THazar;
  HashOperator: TTuz;
  HazarFileHashEngine: THazarHFile;
  StartTime, EndTime: TTime;
  HazarData, HazarKey, GeneratedHash: THazarData;
  DataLength, PasswordLength: Int64;
  FileReader, FileWriter: TFileStream;
  EncryptedFileHeaderFile: file of RHazarEncryptedFileHeader;
  EncryptedFileHeader: RHazarEncryptedFileHeader;
  CmdLine, Operation, SourceFile, DestinationFile, Password: shortstring;
  HashText: string;

  procedure WarnAndExit(Message: shortstring);
  begin
    WriteLn(Message);
    Halt();
  end;

begin
  if ParamCount() = $00 then
  begin
    WriteLn('Hazar File Encryption/Decryption Tool For Testing');
    WriteLn('Uses Hazar(8/64). PRNG based, OTP stream cipher.');
    WriteLn(' ');
    WriteLn(' > To encrypt file: hazarengine E File.dat File.dat.encrypted Password ');
    WriteLn(' ');
    WriteLn(' > To decrypt file: hazarengine D File.dat.encrypted File.dat.decrypted Password');
    WriteLn(' ');
    WriteLn(' > To get hash of a file: hazarengine H File.dat');
    WriteLn(' ');
    WriteLn(' Created By: Alper H. | alper@hazar.com ');
    Exit();
  end;
  if ParamCount() < MinParamCount then
    WarnAndExit('Not enough parameters for operation! Aborting...');
  if ParamCount() > MaxParamCount then
    WarnAndExit('Too many parameters (expected 4) for operation! Aborting...');
  CmdLine := ParamStr($00);
  Operation := ParamStr($01);
  if ((Operation <> OE) and (Operation <> OD) and (Operation <> OH)) then
    WarnAndExit('Unable to identify requested operation.' + #13#10 + 'Please use E: Encryption, D: Decryption, H: File Hash Calculation. Given: [' + Operation + ']');
  SourceFile := ParamStr($02);
  if not FileExists(SourceFile) then
    WarnAndExit('Source file: [' + SourceFile + '] not found!');
  if not (Operation = OH) then
  begin
    DestinationFile := ParamStr($03);
    Password := ParamStr($04);
  end
  else
  begin
    HashText := '';
    HazarFileHashEngine := THazarHFile.StartWithFile(SourceFile);
    GeneratedHash := HazarFileHashEngine.GetFileHash();
    for I := $00 to High(GeneratedHash) do
      HashText := HashText + IntToHex(GeneratedHash[I]);
    HazarFileHashEngine.Free();
    WarnAndExit(HashText);
  end;
  if FileExists(DestinationFile) then
    WarnAndExit('Destination file: [' + DestinationFile + '] already exist!');
  if Password = '' then
    WarnAndExit('Please provide password!');
  PasswordLength := Length(Password);
  for I := $00 to PasswordLength - $01 do
    HazarKey[I] := Byte(Password[I+$01]);
  HashOperator := TTuz.Init();
  HashOperator.Feed(HazarKey, PasswordLength-$01);
  FillChar(GeneratedHash, SizeOf(GeneratedHash), $00);
  GeneratedHash := HashOperator.GetTuzHash();
  HashOperator.Free();
  if Operation = OD then
  begin
    AssignFile(EncryptedFileHeaderFile, SourceFile);
    Reset(EncryptedFileHeaderFile);
    Read(EncryptedFileHeaderFile, EncryptedFileHeader);
    CloseFile(EncryptedFileHeaderFile);
    for I := $00 to DataMax do
      if GeneratedHash[I] <> EncryptedFileHeader.FileHash[I] then
        WarnAndExit('Wrong password!');
  end
  else
  begin
    FileReader := TFileStream.Create(SourceFile, fmOpenRead);
    EncryptedFileHeader.FileHash := GeneratedHash;
    EncryptedFileHeader.FileLength := FileReader.Size;
    FileReader.Free();
  end;
  AssignFile(EncryptedFileHeaderFile, DestinationFile);
  ReWrite(EncryptedFileHeaderFile);
  Write(EncryptedFileHeaderFile, EncryptedFileHeader);
  CloseFile(EncryptedFileHeaderFile);
  FileReader := TFileStream.Create(SourceFile, fmOpenRead);
  FileWriter := TFileStream.Create(DestinationFile, fmOpenReadWrite);
  if Operation = OD then
  begin
    DataLength := EncryptedFileHeader.FileLength;
    FileReader.Position := FileReader.Position + SizeOf(EncryptedFileHeader);
  end
  else
  begin
    DataLength := FileReader.Size;
    FileWriter.Position := FileWriter.Position + SizeOf(EncryptedFileHeader);
  end;
  StartTime := Now();
  HazarOperator := THazar.Initialize(HazarKey, PasswordLength);
  while DataLength > $00 do
  begin
    ReadBytes := FileReader.Read(HazarData, SizeOf(HazarData));
    if ReadBytes > $00 then
    begin
      HazarOperator.ApplyOTP(HazarData);
      FileWriter.Write(HazarData, SizeOf(HazarData));
    end;
    DataLength := DataLength - ReadBytes;
  end;
  if Operation = OD then
    FileWriter.Size := EncryptedFileHeader.FileLength;
  EndTime := Now();
  WriteLn('Total time used: ' + TimeToStr(EndTime-StartTime));
  HazarOperator.Free();
  FileReader.Free();
  FileWriter.Free();
end.
