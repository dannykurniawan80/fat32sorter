unit FAT32;

interface

uses
  Classes,
  FAT32Struct;

const
  SECTOR_SIZE = 512;
  ROOTDIR_START_CLUSTER = 2;

  FAT32_FILSYSTYPE = 'FAT32';
  FAT32_CLUSTER_ENTRY_SIZE = 32 div 8;
  FAT32_CLUSTERS_PER_SECTOR = SECTOR_SIZE div FAT32_CLUSTER_ENTRY_SIZE;

  END_OF_CLUSTER_CHAIN = $0FFFFFFF;  // According to Microsoft, cluster number is only 28 bits long, the upper 4 bits are reserved.

type
  TLFNEntries = array of TFAT32LFNEntry;

  TFileEntry = class
  private
    LFNEntries: TLFNEntries;
    DirEntry: TFAT32DirEntry;

    FLongFileName: string;
    FCreateDateTime: TDateTime;
    FLastAccessDate: TDate;
    FWriteDateTime: TDateTime;

    function GetAttribute: Integer;
    function GetFileName: string;
    function GetShortFileName: string;
    function GetSize: Cardinal;
    function GetFirstClusterNum: Cardinal;

  protected
    constructor Create(ADirEntry: TFAT32DirEntry; ALFNEntries: TLFNEntries);

  public
    function IsDirectory: Boolean;
    function IsFile: Boolean;
    function IsVolume: Boolean;

    property _LFNEntries: TLFNEntries read LFNEntries;
    property _DirEntry: TFAT32DirEntry read DirEntry;

    property FileName: string read GetFileName;
    property ShortFileName: string read GetShortFileName;
    property Attribute: Integer read GetAttribute;
    property Size: Cardinal read GetSize;
    property CreateDateTime: TDateTime read FCreateDateTime;
    property WriteDateTime: TDateTime read FWriteDateTime;
    property LastAccessDate: TDate read FLastAccessDate;

    property FirstClusterNum: Cardinal read GetFirstClusterNum;
  end;

  TFileEntryCompare = function(Item1, Item2: TFileEntry): Integer;
  TFileEntryCompareFunc = reference to function(Item1, Item2: TFileEntry): Integer;

  TFileEntries = class
  private
    FItems: TList;
    FClusterNum: Cardinal;
    FPathNode: string;
    function GetFileEntry(Idx: Integer): TFileEntry;
    function GetCount: Integer;
  public
    constructor Create(ClusterNum: Cardinal; PathNode: string);
    destructor Destroy; override;

    function AddFileEntry(DirEntry: TFAT32DirEntry; LFNEntries: TLFNEntries): Integer;
    procedure DeleteFileEntry(Index: Integer);

    property ClusterNum: Cardinal read FClusterNum;
    property PathNode: string read FPathNode;

    procedure Sort(Compare: TFileEntryCompare); overload;
    procedure Sort(CompareFunc: TFileEntryCompareFunc); overload;
    procedure Move(CurIndex, NewIndex: Integer); overload;
    procedure Move(Item: TFileEntry; NewIndex: Integer); overload;

    function IndexOf(const FileName: string): Integer;

    property Count: Integer read GetCount;
    property Items[Idx: Integer]: TFileEntry read GetFileEntry;
  end;


  TFAT32 = class
  private
    DiskHandle: THandle;
    FAT32BeginSector: Cardinal;
    ClusterBeginSector: Cardinal;
    DirEntriesPerCluster: Integer;

    CachedClusterSector: Cardinal;
    CachedClusterEntry: array[0..FAT32_CLUSTERS_PER_SECTOR - 1] of Cardinal;

    FDrive: string;
    FFAT32Volume: TFAT32Volume;

    procedure CloseDisk;

    function ClusterToSector(ClusterNum: Cardinal): Cardinal;

    function ReadSector(SectorNum: Cardinal; var Buff; NumOfSectors: Cardinal = 1): Boolean;
    function ReadCluster(ClusterNum: Cardinal; var Buff; NumOfClusters: Cardinal = 1): Boolean;

    function WriteSector(SectorNum: Cardinal; var Buff; NumOfSectors: Cardinal = 1): Boolean;
    function WriteCluster(ClusterNum: Cardinal; var Buff; NumOfClusters: Cardinal = 1): Boolean;

    function GetNextClusterNum(ClusterNum: Cardinal): Cardinal;
    function GetFAT32Volume: TFAT32Volume;

  public
    constructor Create(Drive: string; ReadOnly: Boolean);
    destructor Destroy; override;

    function ReadDirEntry(StartClusterNum: Cardinal; PathNode: string = ''): TFileEntries;
    function ReadRootDirEntry: TFileEntries;

    function WriteDirEntry(FileEntries: TFileEntries): Boolean;
    function WriteRootDirEntry(FileEntries: TFileEntries): Boolean;

    property Drive: string read FDrive;
    property FAT32Volume: TFAT32Volume read GetFAT32Volume;
  end;

implementation

uses
  SysUtils,
  Windows;

function GetErrorMessage(ErrCode: Cardinal): string;
var
  MessagePtr: PWideChar;
  MessageSize: Cardinal;
begin
  MessageSize := FormatMessage(
      FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,
      nil, ErrCode, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), @MessagePtr, 0, nil
    );
  Result := MessagePtr;
  LocalFree(MessagePtr);
end;

{ TFileEntry }

constructor TFileEntry.Create(ADirEntry: TFAT32DirEntry; ALFNEntries: TLFNEntries);
var
  i: Integer;
begin
  DirEntry := ADirEntry;
  if Assigned(ALFNEntries) then
    SetLength(LFNEntries, Length(ALFNEntries))
  else
    SetLength(LFNEntries, 0);

  FLongFileName := '';
  for i := 0 to Length(LFNEntries) - 1 do
  begin
    LFNEntries[i] := ALFNEntries[i];
    FLongFileName := LFNEntries[i].LDIR_Name + FLongFileName;
  end;

  if (FLongFileName = '') then
    if (DirEntry.DIR_Attr and ATTR_VOLUME_ID) = 0 then
      FLongFileName := DirEntry.DIR_Name_Format83
    else
      FLongFileName := DirEntry.DIR_Name_Volume;

  FCreateDateTime := DirEntry.DIR_CreateDateTime;
  FLastAccessDate := DirEntry.DIR_LastAccessDate;
  FWriteDateTime := DirEntry.DIR_WriteDateTime;
end;

function TFileEntry.GetAttribute: Integer;
begin
  Result := DirEntry.DIR_Attr;
end;

function TFileEntry.GetFileName: string;
begin
  Result := FLongFileName;
end;

function TFileEntry.GetShortFileName: string;
begin
  if DirEntry.DIR_Attr and 8 = 8 then
    Result := DirEntry.DIR_Name_Volume
  else
    Result := DirEntry.DIR_Name_Format83;
end;

function TFileEntry.GetSize: Cardinal;
begin
  Result := DirEntry.DIR_FileSize;
end;

function TFileEntry.IsDirectory: Boolean;
begin
  Result := DirEntry.DIR_Attr and faDirectory <> 0;
end;

function TFileEntry.IsFile: Boolean;
begin
  Result := DirEntry.DIR_Attr and faDirectory = 0;
end;

function TFileEntry.IsVolume: Boolean;
begin
  Result := DirEntry.DIR_Attr and 8 = 8;
end;

function TFileEntry.GetFirstClusterNum: Cardinal;
begin
  Result := DIREntry.DIR_FirstCluster;
end;


{ TFAT32 }

constructor TFAT32.Create(Drive: string; ReadOnly: Boolean);
var
  FName: string;
  Access: Cardinal;
begin
  CachedClusterSector := 0;

  FDrive := Drive;
  FName := Format('\\.\%s', [Drive]);

  Access := GENERIC_READ;
  if not ReadOnly then Access := Access + GENERIC_WRITE;

  DiskHandle := CreateFile(
      PChar(FName),                                       // lpFileName
      Access,                                             // dwDesiredAccess
      FILE_SHARE_READ or FILE_SHARE_WRITE,                // dwShareMode
      nil,                                                // lpSecurityAttributes
      OPEN_EXISTING,                                      // dwCreationDisposition
      FILE_FLAG_NO_BUFFERING or FILE_FLAG_RANDOM_ACCESS,  // dwFlagsAndAttributes
      0                                                   // hTemplateFile
    );

  if DiskHandle = INVALID_HANDLE_VALUE then
    raise Exception.Create('Failed to open drive!');

  if not ReadSector(0, FFAT32Volume) then
  begin
    CloseDisk;
    raise Exception.Create('Failed to read drive entry!');
  end;

  if FFAT32Volume.BPB_BytesPerSec <> SECTOR_SIZE then
  begin
    CloseDisk;
    raise Exception.Create(Format('Unsupported sector size: %d!', [FFAT32Volume.BPB_BytesPerSec]));
  end;

  if (FFAT32Volume.BS_FilSysType_AsString <> FAT32_FILSYSTYPE) then
  begin
    CloseDisk;
    raise Exception.Create('Drive is not FAT32!');
  end;

  with FFAT32Volume do
  begin
    FAT32BeginSector := BPB_RsvdSecCnt;
    ClusterBeginSector := BPB_RsvdSecCnt + (BPB_NumFATs * BPB_FATSz32);
    DirEntriesPerCluster := (BPB_BytesPerSec * BPB_SecPerClus) div SizeOf(TFAT32DirEntry);
  end;
end;

destructor TFAT32.Destroy;
begin
  CloseDisk;
end;

procedure TFAT32.CloseDisk;
begin
  CloseHandle(DiskHandle);
  DiskHandle := INVALID_HANDLE_VALUE;
end;

function TFAT32.ClusterToSector(ClusterNum: Cardinal): Cardinal;
begin
  Result := ClusterBeginSector + ((ClusterNum - 2) * FFAT32Volume.BPB_SecPerClus);
end;

function TFAT32.ReadSector(SectorNum: Cardinal; var Buff; NumOfSectors: Cardinal): Boolean;
var
  BytesOffset: UInt64;
  Overlapped: TOverlapped;
  BytesRead: Cardinal;
  ErrCode: Cardinal;
begin
  if DiskHandle = INVALID_HANDLE_VALUE then
    raise Exception.Create('Invalid Disk Handle!');

  BytesOffset := UInt64(SectorNum) * FFAT32Volume.BPB_BytesPerSec;
  FillChar(Overlapped, SizeOf(TOverlapped), 0);
  Overlapped.Offset := Int64Rec(BytesOffset).Lo;
  Overlapped.OffsetHigh := Int64Rec(BytesOffset).Hi;

  Result := ReadFile(DiskHandle, Buff, NumOfSectors * SECTOR_SIZE, BytesRead, @Overlapped);
  if Result then
    Result := BytesRead = NumOfSectors * SECTOR_SIZE  // we expect that number of bytes read is full sector...
  else
  begin
    ErrCode := GetLastError;
    OutputDebugString(PChar(Format('READ Sector ERROR: [%d] %s', [ErrCode, GetErrorMessage(ErrCode)])));
  end;
end;

function TFAT32.ReadCluster(ClusterNum: Cardinal; var Buff; NumOfClusters: Cardinal = 1): Boolean;
begin
  Result := ReadSector(ClusterToSector(ClusterNum), Buff, NumOfClusters * FFAT32Volume.BPB_SecPerClus);
end;

function TFAT32.WriteSector(SectorNum: Cardinal; var Buff; NumOfSectors: Cardinal): Boolean;
var
  BytesOffset: UInt64;
  Overlapped: TOverlapped;
  BytesWritten: Cardinal;
  ErrCode: Cardinal;
begin
  if DiskHandle = INVALID_HANDLE_VALUE then
    raise Exception.Create('Invalid Disk Handle!');

  BytesOffset := UInt64(SectorNum) * FFAT32Volume.BPB_BytesPerSec;
  FillChar(Overlapped, SizeOf(TOverlapped), 0);
  Overlapped.Offset := Int64Rec(BytesOffset).Lo;
  Overlapped.OffsetHigh := Int64Rec(BytesOffset).Hi;

  //Result := True; BytesWritten := NumOfSectors * SECTOR_SIZE;
  Result := WriteFile(DiskHandle, Buff, NumOfSectors * SECTOR_SIZE, BytesWritten, @Overlapped);
  if Result then
    Result := BytesWritten = NumOfSectors * SECTOR_SIZE  // we expect that number of bytes written is full sector...
  else
  begin
    ErrCode := GetLastError;
    OutputDebugString(PChar(Format('WRITE Sector ERROR: [%d] %s', [ErrCode, GetErrorMessage(ErrCode)])));
  end;
end;

function TFAT32.WriteCluster(ClusterNum: Cardinal; var Buff; NumOfClusters: Cardinal): Boolean;
begin
  Result := WriteSector(ClusterToSector(ClusterNum), Buff, NumOfClusters * FFAT32Volume.BPB_SecPerClus);
end;

function TFAT32.GetNextClusterNum(ClusterNum: Cardinal): Cardinal;
var
  ClusterEntryByteOffset: Cardinal;
  ClusterSector: Cardinal;
  ClusterIndexOffset: Cardinal;
begin
  ClusterEntryByteOffset := ClusterNum * FAT32_CLUSTER_ENTRY_SIZE;               // Byte offset from start of the FAT32 Table
  ClusterSector := FAT32BeginSector + (ClusterEntryByteOffset div SECTOR_SIZE);  // Sector number where entry located
  ClusterIndexOffset := ClusterNum mod FAT32_CLUSTERS_PER_SECTOR;

  if CachedClusterSector <> ClusterSector then
  begin
    ReadSector(ClusterSector, CachedClusterEntry[0]);
    CachedClusterSector := ClusterSector;
  end;

  Result := CachedClusterEntry[ClusterIndexOffset];
end;


function TFAT32.ReadDirEntry(StartClusterNum: Cardinal; PathNode: string): TFileEntries;
var
  i: Integer;
  ClusterNum: Cardinal;
  EndOfEntry: Boolean;

  DirEntryCluster: array of TFAT32Entry;

  HasLongName: Boolean;
  LFNEntryIdx: Integer;
  LFNEntries: TLFNEntries;
  LastLongNameIdx: Integer;
  CurLongName: string;
  CurLongNameChkSum: Byte;

  NumOfClusters: Integer;
begin
  Result := TFileEntries.Create(StartClusterNum, PathNode);

  ClusterNum := StartClusterNum;
  EndOfEntry := False;

  HasLongName := False;
  CurLongName := '';
  CurLongNameChkSum := 0;

  NumOfClusters := 0;

  SetLength(DirEntryCluster, DirEntriesPerCluster * SizeOf(TFAT32DirEntry));

  repeat
    Inc(NumOfClusters);
    OutputDebugString(PChar(Format('%d. Cluster: [%d]', [NumOfClusters, ClusterNum])));

    ReadCluster(ClusterNum, DirEntryCluster[0]);

    for i := 0 to DirEntriesPerCluster - 1 do
      with DirEntryCluster[i] do
      begin
        if Raw[0] = 0 then  // Check for End of Directory
        begin
          EndOfEntry := True;
          Break;
        end;

        if Raw[0] <> $E5 then
        begin
          // ---- LFN Handling -----
          if (AsDirEntry.DIR_Attr and ATTR_LONG_NAME_MASK) = ATTR_LONG_NAME then
          begin
            // Check if this is end of LFN and we have valid OrderIdx
            if (not HasLongName) and ((AsLFNEntry.LDIR_Ord and $C0) = $40) and (AsLFNEntry.LDIR_Ord - $40 > 0) then
            begin
              HasLongName := True;
              LastLongNameIdx := AsLFNEntry.LDIR_Ord - $40;
              CurLongName := AsLFNEntry.LDIR_Name;
              CurLongNameChkSum := AsLFNEntry.LDIR_ChkSum;

              // Store our first LFNEntry...
              SetLength(LFNEntries, LastLongNameIdx);
              LFNEntryIdx := 0;
              Move(Raw[0], LFNEntries[LFNEntryIdx], SizeOf(TFAT32LFNEntry));
            end
            else if HasLongName then
            begin
              // Check if we have valid LFN sequence
              if (AsLFNEntry.LDIR_Ord = LastLongNameIdx - 1) and (AsLFNEntry.LDIR_Chksum = CurLongNameChkSum) then
              begin
                LastLongNameIdx := AsLFNEntry.LDIR_Ord;
                CurLongName := AsLFNEntry.LDIR_Name + CurLongName;  // Prepend LFN

                // Store LFNEntry...
                Inc(LFNEntryIdx);
                Move(Raw[0], LFNEntries[LFNEntryIdx], SizeOf(TFAT32LFNEntry));
              end
              else
                HasLongName := False;  // ...we have invalid LFN...
            end
            else
              HasLongName := False;  // ...otherwise just ignore... it is a invalid LFN...
          end
          else
          begin
            // ----- Standard DirEntry Handling -----
            case AsDirEntry.DIR_Attr and (ATTR_DIRECTORY or ATTR_VOLUME_ID) of
              0:  // Found a file
                  begin
                    if HasLongName and (CurLongNameChkSum = AsDirEntry.DIR_ChkSum) then
                    begin
                      OutputDebugString(PChar(Format('Found File: [%s] - [%s], Cluster [%d]', [CurLongName, AsDirEntry.DIR_Name_Format83, AsDirEntry.DIR_FirstCluster])));
                      Result.AddFileEntry(AsDirEntry, LFNEntries);
                    end
                    else
                    begin
                      OutputDebugString(PChar(Format('Found File: [%s], Cluster [%d]', [AsDirEntry.DIR_Name_Format83, AsDirEntry.DIR_FirstCluster])));
                      Result.AddFileEntry(AsDirEntry, nil);
                    end;
                  end;
              ATTR_DIRECTORY:
                  begin
                    if HasLongName then
                    begin
                      OutputDebugString(PChar(Format('Found Dir: [%s] - [%s], Cluster [%d]', [CurLongName, AsDirEntry.DIR_Name_Format83, AsDirEntry.DIR_FirstCluster])));
                      Result.AddFileEntry(AsDirEntry, LFNEntries);
                    end
                    else
                    begin
                      OutputDebugString(PChar(Format('Found Dir: [%s], Cluster [%d]', [AsDirEntry.DIR_Name_Format83, AsDirEntry.DIR_FirstCluster])));
                      Result.AddFileEntry(AsDirEntry, nil);
                    end;
                  end;
              ATTR_VOLUME_ID:
                  begin
                    OutputDebugString(PChar(Format('Found Volume: [%s]', [AsDirEntry.DIR_Name_Volume])));
                    Result.AddFileEntry(AsDirEntry, nil);
                  end;
            end;

            HasLongName := False;
            CurLongName := '';
            CurLongNameChkSum := 0;
          end;
        end;

      end;

    // Get next Cluster in chain

    if not EndOfEntry then
    begin
      ClusterNum := GetNextClusterNum(ClusterNum);
      EndOfEntry := ClusterNum and END_OF_CLUSTER_CHAIN = END_OF_CLUSTER_CHAIN;  // End of cluster chain if all 28 bits of LSB is 1...
    end;

  until EndOfEntry;
end;

function TFAT32.WriteDirEntry(FileEntries: TFileEntries): Boolean;
var
  i, j: Integer;
  FAT32EntryIndex: Integer;
  ClusterNum: Cardinal;
  EndOfClusterChain: Boolean;
  BytesReturned: Cardinal;
  ErrCode: Cardinal;

  DirEntryCluster: array of TFAT32Entry;

  procedure WriteEntriesToCluster;
  begin
    WriteCluster(ClusterNum, DirEntryCluster[0]);
    ClusterNum := GetNextClusterNum(ClusterNum);
    FAT32EntryIndex := 0;
  end;

begin
  Result := False;

  // Try to lock the volume if we want to have writing...
  if DeviceIOControl(DiskHandle, FSCTL_LOCK_VOLUME, nil, 0, nil, 0, BytesReturned, nil) then
    try
      SetLength(DirEntryCluster, DirEntriesPerCluster * SizeOf(TFAT32DirEntry));

      FAT32EntryIndex := 0;
      ClusterNum := FileEntries.ClusterNum;

      // Write Dir Entries
      for i := 0 to FileEntries.Count - 1 do
        with FileEntries.Items[i] do
        begin
          // Write LFN Entries first...
          for j := Low(LFNEntries) to High(LFNEntries) do
          begin
            Move(LFNEntries[j], DirEntryCluster[FAT32EntryIndex], SizeOf(TFAT32Entry));
            Inc(FAT32EntryIndex);
            if FAT32EntryIndex >= DirEntriesPerCluster then
              WriteEntriesToCluster;
          end;

          // Then write for file/dir entry
          Move(DirEntry, DirEntryCluster[FAT32EntryIndex], SizeOf(TFAT32Entry));
          Inc(FAT32EntryIndex);
          if FAT32EntryIndex >= DirEntriesPerCluster then
            WriteEntriesToCluster;
        end;

      EndOfClusterChain := ClusterNum and END_OF_CLUSTER_CHAIN = END_OF_CLUSTER_CHAIN;  // End of cluster chain if all 28 bits of LSB is 1...

      // Fill rest of clusters with blanks
      while not EndOfClusterChain do
      begin
        for i := FAT32EntryIndex to DirEntriesPerCluster - 1 do
          FillChar(DirEntryCluster[i], SizeOf(TFAT32Entry), 0);
        WriteEntriesToCluster;
        EndOfClusterChain := ClusterNum and END_OF_CLUSTER_CHAIN = END_OF_CLUSTER_CHAIN;  // End of cluster chain if all 28 bits of LSB is 1...
      end;

      FlushFileBuffers(DiskHandle);

      Result := True;
    finally
      if not DeviceIOControl(DiskHandle, FSCTL_UNLOCK_VOLUME, nil, 0, nil, 0, BytesReturned, nil) then
      begin
        ErrCode := GetLastError;
        OutputDebugString(PChar(Format('ERROR Unlocking VOLUME: [%d] %s', [ErrCode, GetErrorMessage(ErrCode)])));
      end;
    end
  else
  begin
    ErrCode := GetLastError;
    OutputDebugString(PChar(Format('ERROR Locking VOLUME: [%d] %s', [ErrCode, GetErrorMessage(ErrCode)])));
  end;
end;

function TFAT32.ReadRootDirEntry: TFileEntries;
begin
  Result := ReadDirEntry(ROOTDIR_START_CLUSTER);
end;

function TFAT32.WriteRootDirEntry(FileEntries: TFileEntries): Boolean;
begin
  Result := WriteDirEntry(FileEntries);
end;


function TFAT32.GetFAT32Volume: TFAT32Volume;
begin
  Result := FFAT32Volume;
end;


{ TFileEntries }

constructor TFileEntries.Create(ClusterNum: Cardinal; PathNode: string);
begin
  FItems := TList.Create;
  FClusterNum := ClusterNum;
  FPathNode := PathNode;
end;

destructor TFileEntries.Destroy;
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    TFileEntry(FItems.Items[i]).Free;
  FItems.Free;
end;

function TFileEntries.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TFileEntries.GetFileEntry(Idx: Integer): TFileEntry;
begin
  Result := TFileEntry(FItems[Idx]);
end;

function TFileEntries.IndexOf(const FileName: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FItems.Count - 1 do
    if TFileEntry(FItems[i]).FileName = FileName then
    begin
      Result := i;
      Break;
    end;
end;

procedure TFileEntries.Move(CurIndex, NewIndex: Integer);
begin
  FItems.Move(CurIndex, NewIndex);
end;

procedure TFileEntries.Move(Item: TFileEntry; NewIndex: Integer);
begin
  FItems.Move(FItems.IndexOf(Item), NewIndex);
end;

procedure TFileEntries.Sort(Compare: TFileEntryCompare);
begin
  FItems.SortList(
      function(Item1, Item2: Pointer): Integer
      begin
        Result := Compare(TFileEntry(Item1), TFileEntry(Item2));
      end
    );
end;

procedure TFileEntries.Sort(CompareFunc: TFileEntryCompareFunc);
begin
  FItems.SortList(
      function(Item1, Item2: Pointer): Integer
      begin
        Result := CompareFunc(TFileEntry(Item1), TFileEntry(Item2));
      end
    );
end;

function TFileEntries.AddFileEntry(DirEntry: TFAT32DirEntry; LFNEntries: TLFNEntries): Integer;
var
  FileEntry: TFileEntry;
begin
  FileEntry := TFileEntry.Create(DirEntry, LFNEntries);
  Result := FItems.Add(FileEntry);
end;

procedure TFileEntries.DeleteFileEntry(Index: Integer);
begin
  FItems.Delete(Index);
end;


end.
