program hazardemo;

{ =============================================================================
  HazarDemo — Command-line tool for hazario / hazardel
  Usage:
    hazardemo e <input_file> <output_file> <password>   Encrypt
    hazardemo d <input_file> <output_file> <password>   Decrypt
    hazardemo s <file>                                  Secure delete (1 round)
    hazardemo s <file> <rounds>                         Secure delete (N rounds)
  ============================================================================= }

{$APPTYPE CONSOLE}

uses
  SysUtils,
  hazar    in 'hazar.pas',
  hazario  in 'hazario.pas',
  hazardel in 'hazardel.pas';

procedure PrintUsage;
begin
  WriteLn('HazarIO -- File Encryption & Secure Deletion Tool');
  WriteLn('-------------------------------------------------');
  WriteLn('Usage:');
  WriteLn;
  WriteLn('  hazardemo e <input_file> <output_file> <password>');
  WriteLn('      Encrypt input_file -> output_file');
  WriteLn;
  WriteLn('  hazardemo d <input_file> <output_file> <password>');
  WriteLn('      Decrypt input_file -> output_file');
  WriteLn('      Returns error if password is wrong or file is corrupt.');
  WriteLn;
  WriteLn('  hazardemo s <file>');
  WriteLn('      Securely delete <file> using 1 wipe round.');
  WriteLn;
  WriteLn('  hazardemo s <file> <rounds>');
  WriteLn('      Securely delete <file> using N wipe rounds.');
  WriteLn('      Each round = keystream pass + bitwise-inverse pass.');
  WriteLn;
  WriteLn('Exit codes:');
  WriteLn('  0  Success');
  WriteLn('  1  Bad arguments');
  WriteLn('  2  Encryption failed  (path / permissions)');
  WriteLn('  3  Decryption failed  (wrong password or corrupt file)');
  WriteLn('  4  Secure delete failed  (file in use or access denied)');
end;

{ --------------------------------------------------------------------------- }

var
  Mode       : Char;
  InputFile  : string;
  OutputFile : string;
  Password   : string;
  Rounds     : Integer;
  OK         : Boolean;

begin
  if ParamCount < 2 then
  begin
    PrintUsage;
    Halt(1);
  end;

  Mode := LowerCase(ParamStr(1))[1];

  { ----------------------------------------------------------------------- }
  { e — Encrypt                                                              }
  { ----------------------------------------------------------------------- }
  if Mode = 'e' then
  begin
    if ParamCount <> 4 then
    begin
      WriteLn('ERROR: encrypt requires exactly 3 arguments.');
      WriteLn;
      PrintUsage;
      Halt(1);
    end;

    InputFile  := ParamStr(2);
    OutputFile := ParamStr(3);
    Password   := ParamStr(4);

    Write('Encrypting "', InputFile, '" -> "', OutputFile, '" ... ');
    OK := EncryptFile(InputFile, OutputFile, Password);
    if OK then
      WriteLn('OK')
    else
    begin
      WriteLn('FAILED  (check input path / permissions)');
      Halt(2);
    end;
  end

  { ----------------------------------------------------------------------- }
  { d — Decrypt                                                              }
  { ----------------------------------------------------------------------- }
  else if Mode = 'd' then
  begin
    if ParamCount <> 4 then
    begin
      WriteLn('ERROR: decrypt requires exactly 3 arguments.');
      WriteLn;
      PrintUsage;
      Halt(1);
    end;

    InputFile  := ParamStr(2);
    OutputFile := ParamStr(3);
    Password   := ParamStr(4);

    Write('Decrypting "', InputFile, '" -> "', OutputFile, '" ... ');
    OK := DecryptFile(InputFile, OutputFile, Password);
    if OK then
      WriteLn('OK')
    else
    begin
      WriteLn('FAILED  (wrong password or corrupt file)');
      Halt(3);
    end;
  end

  { ----------------------------------------------------------------------- }
  { s — Secure delete                                                        }
  { ----------------------------------------------------------------------- }
  else if Mode = 's' then
  begin
    if (ParamCount < 2) or (ParamCount > 3) then
    begin
      WriteLn('ERROR: secure delete requires 1 or 2 arguments.');
      WriteLn;
      PrintUsage;
      Halt(1);
    end;

    InputFile := ParamStr(2);

    { Optional round count — defaults to 1 }
    Rounds := 1;
    if ParamCount = 3 then
    begin
      Rounds := StrToIntDef(ParamStr(3), -1);
      if Rounds < 1 then
      begin
        WriteLn('ERROR: <rounds> must be a positive integer.');
        Halt(1);
      end;
    end;

    if Rounds = 1 then
      WriteLn('Securely deleting "', InputFile, '" (1 round) ...')
    else
      WriteLn('Securely deleting "', InputFile, '" (', Rounds, ' rounds) ...');

    WriteLn('  Round strategy: [pass 1] keystream overwrite  '+
                               '[pass 2] bitwise-inverse overwrite');

    OK := SecureDelete(InputFile, Rounds);

    if OK then
      WriteLn('Done. File has been wiped and removed.')
    else
    begin
      WriteLn('FAILED  (file in use, already gone, or access denied)');
      Halt(4);
    end;
  end

  { ----------------------------------------------------------------------- }
  { Unknown mode                                                             }
  { ----------------------------------------------------------------------- }
  else
  begin
    WriteLn('ERROR: Unknown mode "', ParamStr(1), '".');
    WriteLn;
    PrintUsage;
    Halt(1);
  end;

end.
