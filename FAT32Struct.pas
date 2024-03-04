unit FAT32Struct;

interface

const
  ATTR_READ_ONLY = $01;
  ATTR_HIDDEN    = $02;
  ATTR_SYSTEM    = $04;
  ATTR_VOLUME_ID = $08;
  ATTR_DIRECTORY = $10;
  ATTR_ARCHIVE   = $20;
  ATTR_LONG_NAME = ATTR_READ_ONLY or
                   ATTR_HIDDEN or
                   ATTR_SYSTEM or
                   ATTR_VOLUME_ID;

  ATTR_LONG_NAME_MASK = ATTR_READ_ONLY or
                        ATTR_HIDDEN or
                        ATTR_SYSTEM or
                        ATTR_VOLUME_ID or
                        ATTR_DIRECTORY or
                        ATTR_ARCHIVE;

type
  TFAT32Volume = packed record
    BS_JmpBoot: array[0..2] of Byte;        // 0xEB, 0x??, 0x90 or 0xEB, 0x??, 0x??
    BS_OEMName: array[1..8] of AnsiChar;    // eg. 'MSWIN4.1'
    BPB_BytesPerSec: Word;                  // 512, 1024, 2048, or 4096 (should be always 512!)
    BPB_SecPerClus: Byte;                   // 1, 2, 4, 8, 16, 32, 64, or 128
    BPB_RsvdSecCnt: Word;                   // usually 0x20
    BPB_NumFATs: Byte;                      // always 2
    BPB_RootEntCnt: Word;                   // Only for FAT12 and FAT16
    BPB_TotSec16: Word;                     // For FAT32, this should be 0
    BPB_Media: Byte;                        // 0xF8 = non-removable media, 0xF0 = removable media
    BPB_FATSz16: Word;                      // Only for FAT12/FAT16. FAT32 always 0
    BPB_SecPerTrk: Word;                    // Only for media that has geometry
    BPB_NumHeads: Word;                     // Only for media that has geometry
    BPB_HiddSec: Cardinal;                  // 0 for media that are not partitioned
    BPB_TotaSec32: Cardinal;                // Total Sectors on the volume.
    // -------------------------------------------------------------------------
    BPB_FATSz32: Cardinal;                  // Num of sectors Size of 1 FAT entry
    BPB_ExtFlags: Word;                     // Bits 0-3: Zero-based number of active FAT. Bits 4-6: Reserved, Bit 7: 0 = mirrored FAT 1 = 1 FAT active, Bits 8-15: Reserved
    BPB_FSVer: Word;                        // Version Number of FAT32 volume. High Byte is Major, Low Byte is Minor.
    BPB_RootClus: Cardinal;                 // Cluster number of the fuirst cluster of the root directory. Usually is 2.
    BPB_FSInfo: Word;                       // Sector number of FSINFO structure in reserved area of FAT32. Usually 1
    BPB_BkBootSec: Word;                    // If non-zero, indicates the sector number in reserved area of the volume of a copy of the boot record. Usually 6.
    BPB_Reserved: array[0..11] of Byte;
    BS_DrvNum: Byte;                        // Int 0x13 drive number (eg. 0x80). 0x00 is for floppy disk
    BS_Reserved1: Byte;                     // Reserved (used by Windows NT). Code that formats FAT volumes should always set this byte to 0
    BS_BootSig: Byte;                       // Extended boot signature (0x29).
    BS_VolID: Cardinal;                     // Volume serial number
    BS_VolLab: array[1..11] of AnsiChar;    // Volume label.This field matches the 11-byte volume label recorded in the root directory.
    BS_FilSysType: array[1..8] of AnsiChar; // Always set to 'FAT32   '.
    Unused: array[0..419] of Byte;
    Signature: Word;                        // Always 0xAA55

    function BS_OEMName_AsString: string;
    function BS_VolID_AsString: string;
    function BS_VolLab_AsString: string;
    function BS_FilSysType_AsString: string;
  end;


  TFAT32ShortName = packed record
  case Integer of
    0: (
         Raw: array[1..11] of AnsiChar;
       );
    1: (
         Name: array[1..8] of AnsiChar;
         Ext: array[1..2] of AnsiChar;
       );
  end;

  TFAT32DirEntry = packed record
    DIR_Name: TFAT32ShortName;              // Short name.
    DIR_Attr: Byte;                         // File attributes:
                                            //   ATTR_READ_ONLY   0x01
                                            //   ATTR_HIDDEN      0x02
                                            //   ATTR_SYSTEM      0x04
                                            //   ATTR_VOLUME_ID   0x08
                                            //   ATTR_DIRECTORY   0x10
                                            //   ATTR_ARCHIVE     0x20
                                            //   ATTR_LONG_NAME   ATTR_READ_ONLY |
                                            //                    ATTR_HIDDEN |
                                            //                    ATTR_SYSTEM |
                                            //                    ATTR_VOLUME_ID
    DIR_NTRes: Byte;                        // Reserved for use by Windows NT. Set value to 0
    DIR_CrtTimeTenth: Byte;                 // Millisecond stamp at file creation time. This field actually
                                            //   contains a count of tenths of a second. The granularity of the
                                            //   seconds part of DIR_CrtTime is 2 seconds so this field is a
                                            //   count of tenths of a second and its valid value range is 0-199 inclusive.
    DIR_CrtTime: Word;                      // Time file was created.
    DIR_CrtDate: Word;                      // Date file was created.
    DIR_LstAccDate: Word;                   // Last access date.
    DIR_FstClusHI: Word;                    // High word of this entry's first cluster number (always 0 for a FAT12 or FAT16 volume).
    DIR_WrtTime: Word;                      // Time of last write. Note that file creation is considered a write.
    DIR_WrtDate: Word;                      // Date of last write. Note that file creation is considered a write.
    DIR_FstClusLO: Word;                    // Low word of this entry's first cluster number.
    DIR_FileSize: Cardinal;                 // 32-bit DWORD holding this file's size in bytes.

    function DIR_Name_Format83: string;
    function DIR_Name_Volume: string;

    function DIR_CreateDateTime: TDateTime;
    function DIR_WriteDateTime: TDateTime;
    function DIR_LastAccessDate: TDate;

    function DIR_FirstCluster: Cardinal;

    function DIR_ChkSum: Byte;
  end;

  TFAT32LFNEntry = packed record
    LDIR_Ord: Byte;                         // Order of the entry. If bit 6 is set (0x40), then this indicates the entry is the last entry.
    LDIR_Name1: array[1..5] of WideChar;    // Characters 1-5 of the long-name sub-component.
    LDIR_Attr: Byte;                        // Attributes - must be ATTR_LONG_NAME (0xF)
    LDIR_Type: Byte;                        // If 0, indicates a directory entry that is a sub-component of long name. NOTE: Other values reserved for future extensions.
    LDIR_ChkSum: Byte;                      // Checksum of name in the short dir entry at the end of long dir set.
    LDIR_Name2: array[1..6] of WideChar;    // Characters 6-11 of the long-name sub-component.
    LDIR_FstClusLO: Word;                   // Must be 0.
    LDIR_Name3: array[1..2] of WideChar;    // Characters 12-13 of the long-name sub-component.

    function LDIR_Name: string;
  end;

  TFAT32Entry = packed record
    case Integer of
      0: ( Raw: array[0..31] of Byte; );
      1: ( AsDirEntry: TFAT32DirEntry; );
      2: ( AsLFNEntry: TFAT32LFNEntry; );
  end;

  TFAT32DirEntrySector = array[0..15] of TFAT32Entry;

implementation

uses
  SysUtils;

type
  TWord2 = packed record
    HiWord: Word;
    LoWord: Word;
  end;

function AnsiStringArrayToString(const Arr; MaxLen: Integer; TrimSpaces: Boolean = False): string;
var
  i: Integer;
  S: AnsiString;
begin
  SetLength(S, MaxLen);
  Move(Arr, S[1], MaxLen);

  for i := 1 to MaxLen do
    if S[i] = #0 then
    begin
      SetLength(S, i);
      Break;
    end;

  if TrimSpaces then
  begin
    i := Length(S);
    while (i > 0) and (S[i] = ' ') do Dec(i);
    SetLength(S, i);
  end;

  Result := string(S);
end;


function FATRawDateToDate(RawDate: Word): TDate;
var
  D, M, Y: Word;
begin
  if RawDate <> 0 then
  begin
    D := RawDate and $1F;
    M := (RawDate shr 5) and $F;
    Y := ((RawDate shr 9) and $7F) + 1980;

    Result := EncodeDate(Y, M, D);
  end
  else
    Result := 0;
end;

function FATRawTimeToTime(RawTime: Word; RawTenth: Byte = 0): TTime;
var
  H, M, S, MS: Word;
begin
  MS := (RawTenth * 10) mod 1000;
  S := ((RawTime and $1F) * 2) + (RawTenth div 100);
  M := (RawTime shr 5) and $3F;
  H := (RawTime shr 11) and $1F;

  if S >= 60 then
  begin
    M := M + (S div 60);
    S := S mod 60;
  end;

  if M >= 60 then
  begin
    H := H + (M div 60);
    M := M mod 60;
  end;

  Result := EncodeTime(H, M, S, MS);
end;


function CalcFAT32ShortNameChksum(ShortName: TFAT32ShortName): Byte;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to 11 do
  begin
    if Result and 1 = 1 then
      Result := $80 + (Result shr 1) + Byte(ShortName.Raw[i])
    else
      Result := (Result shr 1) + Byte(ShortName.Raw[i]);
  end;
end;


function TFAT32Volume.BS_OEMName_AsString: string;
begin
  Result := AnsiStringArrayToString(BS_OEMName, 8);
end;

function TFAT32Volume.BS_VolID_AsString: string;
begin
  Result := IntToHex(BS_VolID, 8);
end;

function TFAT32Volume.BS_VolLab_AsString: string;
begin
  Result := AnsiStringArrayToString(BS_VolLab, 11, True);
end;

function TFAT32Volume.BS_FilSysType_AsString: string;
begin
  Result := AnsiStringArrayToString(BS_FilSysType, 8, True);
end;

{ TFAT32DirEntry }

function TFAT32DirEntry.DIR_ChkSum: Byte;
begin
  Result := CalcFAT32ShortNameChksum(DIR_Name);
end;

function TFAT32DirEntry.DIR_CreateDateTime: TDateTime;
begin
  Result := FATRawDateToDate(DIR_CrtDate) + FATRawTimeToTime(DIR_CrtTime, DIR_CrtTimeTenth);
end;

function TFAT32DirEntry.DIR_FirstCluster: Cardinal;
begin
  Result := (Cardinal(DIR_FstClusHI) shl 16) or Cardinal(DIR_FstClusLO);
end;

function TFAT32DirEntry.DIR_LastAccessDate: TDate;
begin
  Result := FATRawDateToDate(DIR_LstAccDate);
end;

function TFAT32DirEntry.DIR_Name_Format83: string;
var
  Name: AnsiString;
  Ext: AnsiString;
begin
  SetLength(Name, 8);
  SetLength(Ext, 3);
  Move(DIR_Name.Name[1], Name[1], 8);
  Move(DIR_Name.Ext[1], Ext[1], 3);
  Result := Trim(string(Name));
  if Trim(string(Ext)) <> '' then Result := Result + '.' + Trim(string(Ext));
end;

function TFAT32DirEntry.DIR_Name_Volume: string;
var
  Volume: AnsiString;
begin
  SetLength(Volume, 11);
  Move(DIR_Name.Raw[1], Volume[1], 11);
  Result := Trim(string(Volume));
end;

function TFAT32DirEntry.DIR_WriteDateTime: TDateTime;
begin
  Result := FATRawDateToDate(DIR_WrtDate) + FATRawTimeToTime(DIR_WrtTime);
end;

{ TFAT32LFNEntry }

function TFAT32LFNEntry.LDIR_Name: string;
var
  i: Integer;
begin
  SetLength(Result, 13);
  MoveChars(LDIR_Name1[1], Result[1], 5);
  MoveChars(LDIR_Name2[1], Result[6], 6);
  MoveChars(LDIR_Name3[1], Result[12], 2);

  i := 13;
  while (Result[i] = #0) or (Word(Result[i]) = $FFFF) do Dec(i);
  SetLength(Result, i);
end;

end.
