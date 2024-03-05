{ ============================================================================
    File Name   : frmMain.pas
    Author      : Danny Kurniawan <danny.kurniawan@gmail.com>
    Description : Main Form
    License     : GPLv3
  ============================================================================ }
unit frmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  FileReader, Vcl.Menus, System.ImageList, Vcl.ImgList,
  frmSort, frmRename, dmShared;

const
  APPLICATION_NAME = 'FAT32 Sorter';

type
  TMainForm = class(TForm)
    lblDrive: TLabel;
    cbbDriveList: TComboBox;
    btnOpenCloseDrive: TButton;
    btnRefreshDriveList: TButton;
    lblSort: TLabel;
    cbbQuickSortList: TComboBox;
    btnSort: TButton;
    pmSort: TPopupMenu;
    AdvancedSort1: TMenuItem;
    btnRename: TButton;
    lvFolderList: TListView;
    btnReload: TButton;
    btnWriteToDisk: TButton;
    lblNote: TLabel;
    btnQuit: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbbDriveListDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure cbbDriveListChange(Sender: TObject);
    procedure btnOpenCloseDriveClick(Sender: TObject);
    procedure btnRefreshDriveListClick(Sender: TObject);
    procedure btnSortClick(Sender: TObject);
    procedure lvFolderListData(Sender: TObject; Item: TListItem);
    procedure lvFolderListDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure lvFolderListDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure lvFolderListDblClick(Sender: TObject);
    procedure AdvancedSort1Click(Sender: TObject);
    procedure btnRenameClick(Sender: TObject);
    procedure btnWriteToDiskClick(Sender: TObject);
    procedure btnReloadClick(Sender: TObject);
    procedure btnQuitClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

  private
    DriveList: TList;
    FileReader: TFileReader;
    PathEntries: TList;
    ChangeFlag: Boolean;

    SortForm: TSortForm;
    RenameForm: TRenameForm;

    procedure ClearDriveList;
    procedure RefreshDriveList;

    procedure PopulateQuickSortFunctions;
    procedure ClearQuickSortFunctions;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  FileSorter, uMessageDlg;

type
  PDriveInfo = ^TDriveInfo;
  TDriveInfo = record
    DriveLetter: string;
    VolumeName: string;
    FileSystemName: string;
  end;

  TQuickSortItem = class
  private
    FName: string;
    FSorter: TFileSortBase;
  public
    constructor Create(Name: string; SorterClass: TFileSortClass);
    destructor Destroy; override;

    property Name: string read FName write FName;
    property Sorter: TFileSortBase read FSorter;
  end;



procedure GetDriveList(List: TStrings);
var
  i: Integer;
  LogicalDrives: Cardinal;
  DriveLetter: string;
  VolumeName: string;
  MaxComponentLen: Cardinal;
  FileSystemFlag: Cardinal;
  FileSystemName: string;
begin
  List.Clear;
  LogicalDrives := GetLogicalDrives;
  for i := 0 to 25 do
    if (LogicalDrives shr i) and 1 <> 0 then
    begin
      DriveLetter := Chr(65 + i) + ':';
      VolumeName := StringOfChar(#0, MAX_PATH + 1);
      FileSystemName := StringOfChar(#0, MAX_PATH + 1);

      GetVolumeInformation(
          PChar(DriveLetter + '\'),
          @VolumeName[1],
          MAX_PATH,
          nil,
          MaxComponentLen,
          FileSystemFlag,
          @FileSystemName[1],
          MAX_PATH
        );

      VolumeName := Trim(VolumeName);
      FileSystemName := Trim(FileSystemName);

      if VolumeName <> '' then
        VolumeName := ' [' + VolumeName + ']';
      List.Append(Format('%s [%s]%s', [DriveLetter, FileSystemName, VolumeName]));
    end;
end;


procedure TMainForm.ClearDriveList;
var
  DriveInfo: PDriveInfo;
begin
  cbbDriveList.Items.Clear;
  while DriveList.Count > 0 do
  begin
    DriveInfo := PDriveInfo(DriveList.Items[0]);
    DriveList.Delete(0);
    Dispose(DriveInfo);
  end;
end;

procedure TMainForm.RefreshDriveList;
var
  i: Integer;
  LogicalDrives: Cardinal;
  DriveLetter: string;
  VolumeName: string;
  MaxComponentLen: Cardinal;
  FileSystemFlag: Cardinal;
  FileSystemName: string;
  DriveInfo: PDriveInfo;
begin
  cbbDriveList.ItemIndex := -1;
  ClearDriveList;

  LogicalDrives := GetLogicalDrives;
  for i := 0 to 25 do
    if (LogicalDrives shr i) and 1 <> 0 then
    begin
      DriveLetter := Chr(65 + i) + ':';
      VolumeName := StringOfChar(#0, MAX_PATH + 1);
      FileSystemName := StringOfChar(#0, MAX_PATH + 1);

      GetVolumeInformation(
          PChar(DriveLetter + '\'),
          @VolumeName[1],
          MAX_PATH,
          nil,
          MaxComponentLen,
          FileSystemFlag,
          @FileSystemName[1],
          MAX_PATH
        );

      VolumeName := Trim(VolumeName);
      FileSystemName := Trim(FileSystemName);

      New(DriveInfo);
      DriveInfo^.DriveLetter := DriveLetter;
      DriveInfo^.VolumeName := VolumeName;
      DriveInfo^.FileSystemName := FileSystemName;

      DriveList.Add(DriveInfo);

      cbbDriveList.Items.Add(Format('%s [%s] %s', [DriveLetter, FileSystemName, VolumeName]));
    end;
end;

procedure TMainForm.PopulateQuickSortFunctions;
var
  QuickSortItem: TQuickSortItem;
begin
  QuickSortItem := TQuickSortItem.Create('By File Name [A-Z]', TFileSortByFileName);
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('By File Name [Z-A]', TFileSortByFileName);
  QuickSortItem.Sorter.SortDirection := sdDescending;
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('By Modified Date [Earlier First]', TFileSortByModifiedDate);
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('By Modified Date [Latest First]', TFileSortByModifiedDate);
  QuickSortItem.Sorter.SortDirection := sdDescending;
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('By Creation Date [Earlier First]', TFileSortByCreationDate);
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('By Creation Date [Latest First]', TFileSortByCreationDate);
  QuickSortItem.Sorter.SortDirection := sdDescending;
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('By File Size [Smaller First]', TFileSortBySize);
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('By File Size [Bigger First]', TFileSortBySize);
  QuickSortItem.Sorter.SortDirection := sdDescending;
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('(MP3) By Track [0-9]', TFileSortByID3Track);
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('(MP3) By Track [9-0]', TFileSortByID3Track);
  QuickSortItem.Sorter.SortDirection := sdDescending;
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('(MP3) By Title [A-Z]', TFileSortByID3Title);
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('(MP3) By Title [Z-A]', TFileSortByID3Title);
  QuickSortItem.Sorter.SortDirection := sdDescending;
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('(MP3) By Year [0-9]', TFileSortByID3Year);
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  QuickSortItem := TQuickSortItem.Create('(MP3) By Year [9-0]', TFileSortByID3Year);
  QuickSortItem.Sorter.SortDirection := sdDescending;
  cbbQuickSortList.Items.AddObject(QuickSortItem.Name, QuickSortItem);

  cbbQuickSortList.ItemIndex := 0;
end;

procedure TMainForm.ClearQuickSortFunctions;
var
  QuickSortItem: TQuickSortItem;
begin
  with cbbQuickSortList do
    while Items.Count > 0 do
    begin
      QuickSortItem := TQuickSortItem(Items.Objects[0]);
      Items.Delete(0);
      QuickSortItem.Free;
    end;
end;

procedure TMainForm.btnRefreshDriveListClick(Sender: TObject);
begin
  if FileReader.Opened then
    btnOpenCloseDriveClick(btnOpenCloseDrive);  // Toggle to Close
  ClearDriveList;
  RefreshDriveList;
  cbbDriveList.Enabled := True;
end;

procedure TMainForm.btnSortClick(Sender: TObject);
var
  QuickSortItem: TQuickSortItem;
begin
  if cbbQuickSortList.ItemIndex >= 0 then
  begin
    QuickSortItem := TQuickSortItem(cbbQuickSortList.Items.Objects[cbbQuickSortList.ItemIndex]);
    FileReader.CurrentDirEntries.Sort(QuickSortItem.Sorter.Compare);
    lvFolderList.Refresh;
    ChangeFlag := True;
  end;
end;

procedure TMainForm.AdvancedSort1Click(Sender: TObject);
begin
  if FileReader.Opened then
  begin
    if not Assigned(SortForm) then
      SortForm := TSortForm.Create(nil);

    if SortForm.ShowModal = mrOk then
    begin
      FileReader.CurrentDirEntries.Sort(SortForm.Compare);
      lvFolderList.Refresh;
      ChangeFlag := True;
    end;
  end
  else
    ShowMessageDlg('Drive not open!', mtError, [mbOk], 0);
end;

procedure TMainForm.btnRenameClick(Sender: TObject);
begin
  if FileReader.Opened then
  begin
    if not Assigned(RenameForm) then
      RenameForm := TRenameForm.Create(nil);

    RenameForm.SetDirEntries(FileReader.CurrentDirEntries);
    if RenameForm.ShowModal = mrOk then
    begin
      FileReader.ReloadCurrentDirEntries;
      lvFolderList.Refresh;
      ChangeFlag := False;
    end;
  end
  else
    ShowMessageDlg('Drive not open!', mtError, [mbOk], 0);
end;

procedure TMainForm.btnReloadClick(Sender: TObject);
begin
  if FileReader.Opened then
  begin
    if (not ChangeFlag) or
      (ChangeFlag and (ShowMessageDlg(Self, 'Current changes has not written to disk yet. Do you want to reload?', mtConfirmation, mbYesNo, 0) = mrYes)) then
    begin
      FileReader.ReloadCurrentDirEntries;
      lvFolderList.Refresh;
      ChangeFlag := False;
    end;
  end
  else
    ShowMessageDlg('Drive not open!', mtError, [mbOk], 0);
end;

procedure TMainForm.btnWriteToDiskClick(Sender: TObject);
begin
  if Assigned(FileReader) then
    try
      FileReader.WriteCurrentDirEntries;
      ShowMessageDlg('Success!', mtInformation, [mbOk], 0);
    except
      on E: Exception do
        ShowMessageDlg(Format('Failed! Error: [%s]', [E.Message]), mtError, [mbOk], 0);
    end;
end;

procedure TMainForm.btnOpenCloseDriveClick(Sender: TObject);
var
  DriveLetter: string;
begin
  if Assigned(FileReader) then
  begin
    if FileReader.Opened then
    begin
      lvFolderList.Items.Clear;
      FileReader.CloseDrive;

      cbbDriveList.Enabled := True;
      TButton(Sender).Caption := '&Open';

      Caption := APPLICATION_NAME;
    end
    else
      if cbbDriveList.ItemIndex >= 0 then
      begin
        DriveLetter := Copy(cbbDriveList.Items[cbbDriveList.ItemIndex], 1, 2);
        FileReader.OpenDrive(DriveLetter);

        lvFolderList.Items.Count := FileReader.CurrentDirEntries.Count;

        cbbDriveList.Enabled := False;
        TButton(Sender).Caption := '&Close';

        Caption := Format('%s [%s]', [APPLICATION_NAME, FileReader.CurrentPath]);
        ChangeFlag := False;
      end;

    lvFolderList.Refresh;
  end;
end;

procedure TMainForm.btnQuitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.cbbDriveListChange(Sender: TObject);
begin
  with TComboBox(Sender) do
    btnOpenCloseDrive.Enabled := (ItemIndex >= 0) and (PDriveInfo(DriveList.Items[ItemIndex])^.FileSystemName = 'FAT32');;
end;

procedure TMainForm.cbbDriveListDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
  S: string;
begin
  with cbbDriveList.Canvas do
  begin
    if PDriveInfo(DriveList.Items[Index])^.FileSystemName <> 'FAT32' then
    begin
      Font.Style := [fsItalic];
      if odSelected in State then
        Font.Color := clInactiveCaptionText
      else
        Font.Color := clGrayText;
    end
    else
      Font.Style := [fsBold];

    Brush.Style := bsSolid;
    FillRect(Rect);
    InflateRect(Rect, -2, -1);

    S := cbbDriveList.Items[Index];
    DrawText(Handle, PChar(S), Length(S), Rect, DT_LEFT or DT_VCENTER);
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if ChangeFlag then
    CanClose := ShowMessageDlg(Self, 'Current changes has not written to disk yet. Do you want to Quit?', mtConfirmation, mbYesNo, 0) = mrYes
  else
    CanClose := True;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FileReader := TFileReader.Create;
  DriveList := TList.Create;
  PathEntries := TList.Create;

  SortForm := nil;
  RenameForm := nil;

  RefreshDriveList;

  PopulateQuickSortFunctions;

  Caption := APPLICATION_NAME;
  ChangeFlag := False;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(RenameForm) then
    RenameForm.Free;
  if Assigned(SortForm) then
    SortForm.Free;

  ClearDriveList;
  FileReader.Free;

  ClearQuickSortFunctions;

  PathEntries.Free;
  DriveList.Free;
end;

procedure TMainForm.lvFolderListData(Sender: TObject; Item: TListItem);
var
  SizeStr: string;
begin
  if FileReader.Opened then
    with FileReader.CurrentDirEntries.Items[Item.Index] do
    begin
      if IsDirectory then
        Item.ImageIndex := 0
      else if IsFile then
      begin
        if Assigned(ID3) then
          Item.ImageIndex := 2
        else
          Item.ImageIndex := 1;
      end
      else
        Item.ImageIndex := -1;

      Item.Caption := FileName;
      SizeStr := '';

      Item.SubItems.Append(FormatDateTime('dd-mmm-yyyy hh:nn:ss', WriteDateTime));
      Item.SubItems.Append(FormatDateTime('dd-mmm-yyyy hh:nn:ss', CreateDateTime));

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

procedure TMainForm.lvFolderListDblClick(Sender: TObject);
var
  PrevDirName, SelectedName: string;
  Selected: TDirEntryItem;
begin
  if FileReader.Opened and (lvFolderList.ItemIndex >= 0) then
  begin
    PrevDirName := FileReader.CurrentDir;
    Selected := FileReader.CurrentDirEntries.Items[lvFolderList.ItemIndex];
    SelectedName := Selected.FileName;

    if Selected.IsDirectory then
      if Selected.FileName <> '.' then
      begin
        FileReader.ChDir(Selected);

        lvFolderList.Items.Count := FileReader.CurrentDirEntries.Count;
        lvFolderList.Refresh;
        lvFolderList.ClearSelection;

        if (SelectedName = '..') and (PrevDirName <> '') then
          lvFolderList.ItemIndex := FileReader.CurrentDirEntries.IndexOf(PrevDirName);

        Caption := FileReader.CurrentPath;
      end;
  end;
end;

procedure TMainForm.lvFolderListDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  i: Integer;
  DropItemIndex, SelectionCount: Integer;
  DropItem: TListItem;
  MovedItemList: TList;
begin
  SelectionCount := 0;
  if Sender = Source then
  begin
    MovedItemList := TList.Create;
    try
      with TListView(Sender) do
      begin
        for i := 0 to Items.Count - 1 do
          if Items[i].Selected then
            with FileReader.CurrentDirEntries.Items[i] do
              if (not (IsDirectory and ((FileName = '.') or (FileName = '..')))) and (not IsVolume) then  // Prevent moving Volume, '.', and '..' entries...
              begin
                MovedItemList.Add(Pointer(i));
                Inc(SelectionCount);
              end;

        DropItem := GetItemAt(X, Y);
        if DropItem <> nil then
        begin
          DropItemIndex := DropItem.Index;

          // If user dropped over Volume, '.', or '..' entries, force it to the next index,
          // since VolumeID, '.', and '..' must be the first item in directory...
          if DropItemIndex <= 1 then
            with FileReader.CurrentDirEntries.Items[DropItemIndex] do
              if IsVolume then
                DropItemIndex := DropItemIndex + 1
              else if IsDirectory then
                if ((FileName = '.') or (FileName = '..')) then
                  DropItemIndex := 2;
        end
        else
          DropItemIndex := FileReader.CurrentDirEntries.Count - 1;

        // Move selected items
        for i := 0 to MovedItemList.Count - 1 do
          FileReader.CurrentDirEntries.Items[Integer(MovedItemList.Items[i])].Index := DropItemIndex + i;

        ClearSelection;
        if DropItemIndex >= 0 then
        begin
          ItemIndex := DropItemIndex;
          for i := 1 to SelectionCount - 1 do
            Items[DropItemIndex + i].Selected := True;
        end;

        Refresh;
        ChangeFlag := True;
      end;
    finally
      MovedItemList.Free;
    end;
  end;
end;

procedure TMainForm.lvFolderListDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept := Sender = lvFolderList;
end;


{ TQuickSortItem }

constructor TQuickSortItem.Create(Name: string; SorterClass: TFileSortClass);
begin
  FName := Name;
  FSorter := SorterClass.Create;
end;

destructor TQuickSortItem.Destroy;
begin
  FSorter.Free;
  inherited;
end;

end.
