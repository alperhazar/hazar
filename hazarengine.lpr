program hazarengine;

uses
  sysutils, Classes, hazar, hazarh;

const
  OE = 'E';
  OD = 'D';

type
  RHazarEncryptedFileHeader = record
    FileHash: THazarData;
    FileLength: Int64;
  end;

var
  I, ReadBytes: Integer;
  HazarOperator: THazar;
  HazarHashOperator: THazarH;
  StartTime, EndTime: TTime;
  HazarData, HazarKey, GeneratedHash: THazarData;
  DataLength, PasswordLength: Int64;
  FileReader, FileWriter: TFileStream;
  EncryptedFileHeaderFile: file of RHazarEncryptedFileHeader;
  EncryptedFileHeader: RHazarEncryptedFileHeader;
  CmdLine, Operation, SourceFile, DestinationFile, Password: shortstring;
  Parameters: array [$00..$04] of shortstring;

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
    WriteLn(' Created By: Alper H. | alper@hazar.com ');
    Exit();
  end;
  if ParamCount() < High(Parameters) then
  begin
    WriteLn('Not enough parameters for operation! Aborting...');
    Exit();
  end;
  if ParamCount() > High(Parameters) then
  begin
    WriteLn('Too many parameters (expected 4) for operation! Aborting...');
    Exit();
  end;
  CmdLine := ParamStr($00);
  Operation := ParamStr($01);
  SourceFile := ParamStr($02);
  DestinationFile := ParamStr($03);
  Password := ParamStr($04);
  if ((Operation <> OE) and (Operation <> OD)) then
  begin
    WriteLn('Unable to identify requested operation.');
    WriteLn('Please use E: Encryption, D: Decryption. Given: [' + Operation + ']');
    Exit();
  end;
  if not FileExists(SourceFile) then
  begin
    WriteLn('Source file: [' + SourceFile + '] not found!');
    Exit();
  end;
  if FileExists(DestinationFile) then
  begin
    WriteLn('Destination file: [' + DestinationFile + '] already exist!');
    Exit();
  end;
  if Password = '' then
  begin
    WriteLn('Please provide password!');
    Exit();
  end;
  PasswordLength := Length(Password);
  for I := $00 to PasswordLength - $01 do
    HazarKey[I] := Byte(Password[I+$01]);
  HazarHashOperator := THazarH.Start(HazarKey, PasswordLength-$01);
  FillChar(GeneratedHash, SizeOf(GeneratedHash), $00);
  GeneratedHash := HazarHashOperator.Feed(HazarKey);
  if Operation = OD then
  begin
    AssignFile(EncryptedFileHeaderFile, SourceFile);
    Reset(EncryptedFileHeaderFile);
    Read(EncryptedFileHeaderFile, EncryptedFileHeader);
    CloseFile(EncryptedFileHeaderFile);
    for I := $00 to DataMax do
    begin
      if GeneratedHash[I] <> EncryptedFileHeader.FileHash[I] then
      begin
        WriteLn('Wrong password!');
        Exit();
      end;
    end;
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
