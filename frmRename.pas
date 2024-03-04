unit frmRename;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  FileReader, Vcl.Samples.Spin;

type
  TRenameForm = class(TForm)
    gbOptions: TGroupBox;
    lblFileName: TLabel;
    cbbFileName: TComboBox;
    cbRemovePrefix: TCheckBox;
    cbRenameDirs: TCheckBox;
    cbDifferentDirAndFileNumbers: TCheckBox;
    cbDigits: TCheckBox;
    spDigits: TSpinEdit;
    btnPreview: TButton;
    btnReset: TButton;
    btnApply: TButton;
    btnCancel: TButton;
    lvFolderList: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvFolderListData(Sender: TObject; Item: TListItem);
    procedure btnPreviewClick(Sender: TObject);
    procedure cbbFileNameChange(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure cbRenameDirsClick(Sender: TObject);
    procedure cbDigitsClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    PreviewList: TList;
    ChangeFlag: Boolean;

    procedure ClearPreviewList;
    procedure DoPreview;
    function ApplyChanges: Boolean;
  public
    procedure SetDirEntries(const DirEntries: TDirEntries);
  end;

implementation

{$R *.dfm}

uses
  uMessageDlg;

const
  FileRenameOptionList: array[0..3] of string = (
      'Prefix with current File Position',
      'Prefix with ID3 Track Number',
      'Prefix with ID3 Disc & Track Number',
      'Remove Number Prefixes'
    );

  RENAME_PREFIX_FILEPOS        = 0;
  RENAME_PREFIX_ID3_TRACK      = 1;
  RENAME_PREFIX_ID3_DISC_TRACK = 2;
  RENAME_REMOVE_PREFIX         = 3;

type
  TPreviewItem = class
  private
    FDirEntryItem: TDirEntryItem;
    FNewFileName: string;

    function GetIsRenamed: Boolean;
  public
    constructor Create(const DirEntryItem: TDirEntryItem);

    procedure Reset;

    property DirEntryItem: TDirEntryItem read FDirEntryItem;
    property NewFileName: string read FNewFileName write FNewFileName;
    property IsRenamed: Boolean read GetIsRenamed;
  end;

{ TRenameForm }

procedure TRenameForm.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  PreviewList := TList.Create;
  for i := Low(FileRenameOptionList) to High(FileRenameOptionList) do
    cbbFileName.Items.Add(FileRenameOptionList[i]);
  cbbFileName.ItemIndex := 0;

  ChangeFlag := False;  // Reset
end;

procedure TRenameForm.FormDestroy(Sender: TObject);
begin
  ClearPreviewList;
  PreviewList.Free;
end;

procedure TRenameForm.lvFolderListData(Sender: TObject; Item: TListItem);
var
  SizeStr: string;
begin
  if Item <> nil then
    with TPreviewItem(PreviewList.Items[Item.Index]) do
    begin
      Item.Caption := NewFileName;
      SizeStr := '';

      with DirEntryItem do
      begin
        Item.SubItems.Append(FormatDateTime('dd-mmm-yyyy hh:nn:ss', WriteDateTime));

        if Attribute and faDirectory <> 0 then
          Item.SubItems.Append('File folder')
        else if Attribute and 8 <> 0 then
          Item.SubItems.Append('Volume ID')
        else
        begin
          Item.SubItems.Append('File');
          SizeStr := FormatFloat('#,##0', Size);
        end;

        Item.SubItems.Append(SizeStr);

        if Assigned(ID3) then
          with ID3 do
          begin
            Item.SubItems.Append(IntToStr(Track));
            Item.SubItems.Append(Album);
            Item.SubItems.Append(Artist);
            Item.SubItems.Append(Title);
            Item.SubItems.Append(IntToStr(Year));
            Item.SubItems.Append(IntToStr(Disc));
          end;
      end;
    end;
end;

procedure TRenameForm.DoPreview;

  function GetNumOfDigits(n: Integer): Integer;
  begin
    if n = 0 then
      Result := 1
    else
    begin
      Result := 0;
      while n > 0 do
      begin
        n := n div 10;
        Inc(Result);
      end;
    end;
  end;

  function DetectPrefix(S: string): Integer;  // Detects if S have prefix, returns index of first character that is not part of the prefix.
  var
    i: Integer;
    State: Integer;
  begin
    State := 0;  // 0 = Begin; 1 = First numbers found; 2 = Hypen found; 3 = Second numbers found; 4 = Period found; 5 = Spaces found; 6 = Non-Number found.

    i := 1;
    while (i <= Length(S)) and (State <> 6) do
    begin
      case State of
        0:  // Begin
          if CharInSet(S[i], ['0'..'9']) then
            State := 1
          else
            State := 6;
        1:  // First numbers found
          if not CharInSet(S[i], ['0'..'9', '-', '.', ' ']) then
          begin
            i := 1;
            State := 6;
          end
          else
            case S[i] of
              '-': State := 2;
              '.': State := 4;
              ' ': State := 5;
            end;
        2:  // Hypen found
          if CharInSet(S[i], ['0'..'9']) then
            State := 3
          else
          begin
            i := 1;
            State := 6;
          end;
        3:  // Second numbers found
          if not CharInSet(S[i], ['0'..'9', '.', ' ']) then
          begin
            i := 1;
            State := 6;
          end
          else
            case S[i] of
              '.': State := 4;
              ' ': State := 5;
            end;
        4:  // Period found
          if S[i] = ' ' then
            State := 5
          else
            State := 6;
        5:  // Spaces found (Trim it)
          if S[i] <> ' ' then
            State := 6;
      end;

      if State < 6 then
        Inc(i);
    end;

    Result := i;
  end;

  function GetNewFileName(Digits, Num: Integer; FileName: string; DirEntryItem: TDirEntryItem): string;
  begin
    case cbbFileName.ItemIndex of
      RENAME_PREFIX_FILEPOS:
        Result := Format('%.*d. ', [Digits, Num]) + FileName;
      RENAME_PREFIX_ID3_TRACK:
        if Assigned(DirEntryItem.ID3) then
          Result := Format('%.*d. ', [Digits, DirEntryItem.ID3.Track]) + FileName;
      RENAME_PREFIX_ID3_DISC_TRACK:
        if Assigned(DirEntryItem.ID3) then
          Result := Format('%.*d-%.*d. ', [Digits, DirEntryItem.ID3.Disc, Digits, DirEntryItem.ID3.Track]) + FileName;
    end;
  end;

var
  i, n: Integer;
  Num, FileNum, DirNum: Integer;
  Digits: Integer;
  FileName: string;
  DoRename: Boolean;
begin
  FileNum := 0;
  DirNum := 0;

  if cbDigits.Checked then
    Digits := spDigits.Value
  else
  begin
    if PreviewList.Count > 0 then
    begin
      with TPreviewItem(PreviewList.Items[0]) do
        if DirEntryItem.IsDirectory and (DirEntryItem.FileName = '.') then
          Digits := GetNumOfDigits(PreviewList.Count - 2)
        else
          Digits := GetNumOfDigits(PreviewList.Count);
    end
    else
      Digits := 1;
  end;

  for i := 0 to PreviewList.Count - 1 do
    with TPreviewItem(PreviewList.Items[i]) do
    begin

      DoRename := False;

      if DirEntryItem.IsFile then
      begin
        DoRename := True;
        Inc(FileNum);
      end
      else if DirEntryItem.IsDirectory and (DirEntryItem.FileName <> '.') and (DirEntryItem.FileName <> '..') then
        if cbRenameDirs.Checked then
        begin
          DoRename := True;
          if cbDifferentDirAndFileNumbers.Checked then
            Inc(DirNum)
          else
            Inc(FileNum);
        end;

      if DoRename then
      begin
        ChangeFlag := True;

        if DirEntryItem.IsDirectory and cbRenameDirs.Checked and cbDifferentDirAndFileNumbers.Checked then
          Num := DirNum
        else
          Num := FileNum;

        FileName := DirEntryItem.FileName;

        if ((cbbFileName.ItemIndex = RENAME_REMOVE_PREFIX) or cbRemovePrefix.Checked) then
        begin
          n := DetectPrefix(FileName);
          if n < Length(FileName) then
            FileName := Copy(FileName, n, Length(FileName));
        end;

        if cbbFileName.ItemIndex = RENAME_REMOVE_PREFIX then
          NewFileName := FileName
        else
          NewFileName := GetNewFileName(Digits, Num, FileName, DirEntryItem);
      end;
    end;
end;

function TRenameForm.ApplyChanges: Boolean;
var
  i: Integer;
  OrigFilePath: string;
  NewFilePath: string;
begin
  Result := True;

  for i := 0 to PreviewList.Count - 1 do
    with TPreviewItem(PreviewList.Items[i]) do
      if IsRenamed then
        try
          OrigFilePath := DirEntryItem.Path + DirEntryItem.FileName;
          NewFilePath := DirEntryItem.Path + NewFileName;
          {$IFDEF DEBUG}
          OutputDebugString(PChar(Format('RENAME: [%s] -> [%s]', [OrigFilePath, NewFilePath])));
          {$ENDIF}
          if not RenameFile(OrigFilePath, NewFilePath) then
            raise Exception.Create('Failed to rename file.');
        except
          on E: Exception do
            if ShowMessageDlg(
                Self,
                Format('Exception occurred when trying to rename [%s].'#13#10'Message: %s'#13#10#13#10'Do you want to continue?', [OrigFilePath, E.Message]),
                mtError,
                mbYesNo,
                0
              ) = mrNo then
            begin
              Result := False;
              Break;
            end;
        end;
end;

procedure TRenameForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if ChangeFlag then
    CanClose := ShowMessageDlg(Self, 'Are you sure you want to cancel changes?', mtConfirmation, mbYesNo, 0) = mrYes
  else
    CanClose := True;
end;

procedure TRenameForm.btnApplyClick(Sender: TObject);
begin
  if ChangeFlag then
    case ShowMessageDlg(Self, 'Apply changes?', mtConfirmation, mbYesNoCancel, 0) of
      mrYes:  // Apply Changes...
        if ApplyChanges then
        begin
          ChangeFlag := False;  // Assume no more changes (for FormCloseQuery)
          ModalResult := mrOk;
        end;
      mrNo:
        begin
          ChangeFlag := False;  // Assume all changes discarded (for FormCloseQuery)
          ModalResult := mrCancel;
        end;
      mrCancel:
        begin
          // Do Nothing...
        end;
    end;
end;

procedure TRenameForm.btnPreviewClick(Sender: TObject);
begin
  DoPreview;
  lvFolderList.Refresh;
end;

procedure TRenameForm.btnResetClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to PreviewList.Count - 1 do
    TPreviewItem(PreviewList.Items[i]).Reset;
  lvFolderList.Refresh;

  ChangeFlag := False;  // Reset
end;

procedure TRenameForm.cbbFileNameChange(Sender: TObject);
begin
  cbRemovePrefix.Enabled := cbbFileName.ItemIndex <> RENAME_REMOVE_PREFIX;

  if cbbFileName.ItemIndex = RENAME_PREFIX_ID3_DISC_TRACK then
  begin
    // We don't support renaming folders in this mode...
    cbRenameDirs.Checked := False;
    cbRenameDirs.Enabled := False;
    cbDifferentDirAndFileNumbers.Enabled := False;
  end
  else
  begin
    cbRenameDirs.Enabled := True;
    cbRenameDirsClick(cbRenameDirs);
  end;
end;

procedure TRenameForm.cbDigitsClick(Sender: TObject);
begin
  spDigits.Enabled := cbDigits.Checked;
end;

procedure TRenameForm.cbRenameDirsClick(Sender: TObject);
begin
  cbDifferentDirAndFileNumbers.Enabled := cbRenameDirs.Checked;
end;

procedure TRenameForm.ClearPreviewList;
var
  PreviewItem: TPreviewItem;
begin
  while PreviewList.Count > 0 do
  begin
    PreviewItem := TPreviewItem(PreviewList.Items[0]);
    PreviewList.Delete(0);
    PreviewItem.Free;
  end;
end;

procedure TRenameForm.SetDirEntries(const DirEntries: TDirEntries);
var
  i: Integer;
  PreviewItem: TPreviewItem;
begin
  ClearPreviewList;

  for i := 0 to DirEntries.Count - 1 do
  begin
    PreviewItem := TPreviewItem.Create(DirEntries.Items[i]);
    PreviewList.Add(PreviewItem);
  end;

  lvFolderList.Items.Count := DirEntries.Count;
  lvFolderList.Refresh;
end;

{ TPreviewItem }

constructor TPreviewItem.Create(const DirEntryItem: TDirEntryItem);
begin
  FDirEntryItem := DirEntryItem;
  Reset;
end;

function TPreviewItem.GetIsRenamed: Boolean;
begin
  Result := FNewFileName <> FDirEntryItem.FileName;
end;

procedure TPreviewItem.Reset;
begin
  FNewFileName := FDirEntryItem.FileName;
end;

end.
