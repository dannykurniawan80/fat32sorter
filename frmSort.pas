unit frmSort;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Samples.Spin,
  FileSorter, FileReader, frSortPanel;

type
  TSortForm = class(TForm)
    sbxSortOrder: TScrollBox;
    lblSortOrder: TLabel;
    lblDirectorySort: TLabel;
    cbbDirectorySort: TComboBox;
    lblMP3Sort: TLabel;
    cbbMP3FSort: TComboBox;
    btnAddCriteria: TButton;
    btnRemoveCriteria: TButton;
    btnOk: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddCriteriaClick(Sender: TObject);
    procedure btnRemoveCriteriaClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
  private
    SortList: TList;
    SortListPanel: TList;

    procedure ExchangeSortPanel(Panel1, Panel2: TSortFrame);

    procedure OnPanelChangeSortType(Sender: TObject);
    procedure OnPanelMoveUp(Sender: TObject);
    procedure OnPanelMoveDown(Sender: TObject);

    procedure AddSortItem;
    procedure BuildSortList;
    procedure ClearSortList;
  public
    function Compare(const Left, Right: TDirEntryItem): Integer;
  end;


implementation

{$R *.dfm}

uses
  uMessageDlg;

type
  TSortType = record
    Name: string;
    SortClass: TFileSortClass;
  end;

const
  SortTypeList: array[0..9] of TSortType = (
      ( Name: 'File Name'; SortClass: TFileSortByFileName ),
      ( Name: 'File Modified Date'; SortClass: TFileSortByModifiedDate ),
      ( Name: 'File Creation Date'; SortClass: TFileSortByCreationDate ),
      ( Name: 'File Size'; SortClass: TFileSortBySize ),
      ( Name: 'ID3 Track'; SortClass: TFileSortByID3Track ),
      ( Name: 'ID3 Disc'; SortClass: TFileSortByID3Disc ),
      ( Name: 'ID3 Title'; SortClass: TFileSortByID3Title ),
      ( Name: 'ID3 Artist'; SortClass: TFileSortByID3Artist ),
      ( Name: 'ID3 Album'; SortClass: TFileSortByID3Album ),
      ( Name: 'ID3 Year'; SortClass: TFileSortByID3Year )
    );

var
  SortTypeListAsString: string;

{ TSortForm }

procedure TSortForm.btnAddCriteriaClick(Sender: TObject);
begin
  AddSortItem;
end;

procedure TSortForm.btnRemoveCriteriaClick(Sender: TObject);
var
  i: Integer;
  SortPanel: TSortFrame;
begin
  for i := SortListPanel.Count - 1 downto 0 do
  begin
    SortPanel := TSortFrame(SortListPanel.Items[i]);
    if SortPanel.cbSelect.Checked then
    begin
      SortListPanel.Delete(i);
      SortPanel.Free;
    end;
  end;

  for i := 0 to SortListPanel.Count - 1 do
    with TSortFrame(SortListPanel.Items[i]) do
    begin
      Tag := i;
      Top := i * Height;
      cbbSortBy.Tag := i;
    end;
end;

procedure TSortForm.FormCreate(Sender: TObject);
begin
  SortList := TList.Create;
  SortListPanel := TList.Create;
  AddSortItem;
end;

procedure TSortForm.FormDestroy(Sender: TObject);
begin
  ClearSortList;
  SortListPanel.Free;
  SortList.Free;
end;

procedure TSortForm.OnPanelChangeSortType(Sender: TObject);
var
  PanelIndex: Integer;
  SortTypeIndex: Integer;
begin
  PanelIndex := TComboBox(Sender).Tag;
  SortTypeIndex := TComboBox(Sender).ItemIndex;

  if SortTypeIndex >= 0 then
    with TSortFrame(SortListPanel.Items[PanelIndex]) do
      cbCaseInsensitive.Visible :=
        SortTypeList[SortTypeIndex].SortClass.InheritsFrom(TFileSortByStringBase) or
        SortTypeList[SortTypeIndex].SortClass.InheritsFrom(TFileSortByID3StringBase);
end;

procedure TSortForm.ExchangeSortPanel(Panel1, Panel2: TSortFrame);
var
  TempSelect: Boolean;
  TempSortBy: Integer;
  TempSortDirection: Integer;
  TempCaseInsensitive: Boolean;
  TempCaseInsensitiveVisible: Boolean;
begin
  with Panel1 do
  begin
    TempSelect := cbSelect.Checked;
    TempSortBy := cbbSortBy.ItemIndex;
    TempSortDirection := cbbSortDirection.ItemIndex;
    TempCaseInsensitive := cbCaseInsensitive.Checked;
    TempCaseInsensitiveVisible := cbCaseInsensitive.Visible;

    cbSelect.Checked := Panel2.cbSelect.Checked;
    cbbSortBy.ItemIndex := Panel2.cbbSortBy.ItemIndex;
    cbbSortDirection.ItemIndex := Panel2.cbbSortDirection.ItemIndex;
    cbCaseInsensitive.Checked := Panel2.cbCaseInsensitive.Checked;
    cbCaseInsensitive.Visible := Panel2.cbCaseInsensitive.Visible;
  end;

  with Panel2 do
  begin
    cbSelect.Checked := TempSelect;
    cbbSortBy.ItemIndex := TempSortBy;
    cbbSortDirection.ItemIndex := TempSortDirection;
    cbCaseInsensitive.Checked := TempCaseInsensitive;
    cbCaseInsensitive.Visible := TempCaseInsensitiveVisible;
  end;
end;

procedure TSortForm.OnPanelMoveUp(Sender: TObject);
var
  PanelIndex: Integer;
begin
  PanelIndex := TSpinButton(Sender).Tag;
  if PanelIndex > 0 then
    ExchangeSortPanel(TSortFrame(SortListPanel.Items[PanelIndex - 1]), TSortFrame(SortListPanel[PanelIndex]));
end;

procedure TSortForm.OnPanelMoveDown(Sender: TObject);
var
  PanelIndex: Integer;
begin
  PanelIndex := TSpinButton(Sender).Tag;
  if PanelIndex < SortListPanel.Count - 1 then
    ExchangeSortPanel(TSortFrame(SortListPanel.Items[PanelIndex + 1]), TSortFrame(SortListPanel[PanelIndex]));
end;

procedure TSortForm.AddSortItem;
var
  SortPanel: TSortFrame;
  PanelIndex: Integer;
begin
  SortPanel := TSortFrame.Create(sbxSortOrder);

  PanelIndex := SortListPanel.Add(SortPanel);
  with SortPanel do
  begin
    Name := '';
    Tag := PanelIndex;
    Parent := sbxSortOrder;
    Left := 0;
    Top := PanelIndex * Height;

    cbbSortBy.Tag := PanelIndex;
    cbbSortBy.Items.Text := SortTypeListAsString;
    cbbSortBy.OnChange := OnPanelChangeSortType;

    sbtnUpDown.Tag := PanelIndex;
    sbtnUpDown.OnUpClick := OnPanelMoveUp;
    sbtnUpDown.OnDownClick := OnPanelMoveDown;
  end;
end;

procedure TSortForm.btnOkClick(Sender: TObject);
begin
  if SortListPanel.Count > 0 then
  begin
    ClearSortList;
    BuildSortList;
    ModalResult := mrOk;
  end
  else
    ShowMessageDlg(Self, 'You need to define at least 1 criteria!', mtError, [mbOk], 0);
end;

procedure TSortForm.BuildSortList;
const
  SortDirectionMap: array[0..1] of TSortDirection = ( sdAscending, sdDescending );
  SortDirectoryOptionMap: array[0..2] of TSortDirectoryOption = ( sdoDirectoryFirst, sdoDirectoryLast, sdoNone );
var
  i: Integer;
  FileSort: TFileSortBase;
begin
  for i := 0 to SortListPanel.Count - 1 do
    with TSortFrame(SortListPanel.Items[i]) do
    begin
      FileSort := SortTypeList[cbbSortBy.ItemIndex].SortClass.Create;

      FileSort.SortDirection := SortDirectionMap[cbbSortDirection.ItemIndex];
      FileSort.SortDirectoryOption := SortDirectoryOptionMap[cbbDirectorySort.ItemIndex];

      if cbCaseInsensitive.Visible then
      begin
        if FileSort.InheritsFrom(TFileSortByStringBase) then
          TFileSortByStringBase(FileSort).CaseSensitive := not cbCaseInsensitive.Checked
        else if FileSort.InheritsFrom(TFileSortByID3StringBase) then
          TFileSortByID3StringBase(FileSort).CaseSensitive := not cbCaseInsensitive.Checked;
      end;

      if FileSort.InheritsFrom(TFileSortByID3Base) then
        TFileSortByID3Base(FileSort).SortHasID3First := cbbMP3FSort.ItemIndex = 0;

      SortList.Add(FileSort);
    end;
end;

procedure TSortForm.ClearSortList;
var
  SortItem: TFileSortBase;
begin
  while SortList.Count > 0 do
  begin
    SortItem := TFileSortBase(SortList.Items[0]);
    SortList.Delete(0);
    SortItem.Free;
  end;
end;


function TSortForm.Compare(const Left, Right: TDirEntryItem): Integer;
var
  i: Integer;
begin
  Result := 0;

  for i := 0 to SortList.Count - 1 do
    with TFileSortBase(SortList.Items[i]) do
    begin
      Result := Compare(Left, Right);
      if Result <> 0 then
        Break;
    end;

  if Result = -99 then
    Result := 0;
end;


var
  i: Integer;
initialization
  SortTypeListAsString := '';
  for i := Low(SortTypeList) to High(SortTypeList) do
  begin
    if i > 0 then SortTypeListAsString := SortTypeListAsString + #13#10;
    SortTypeListAsString := SortTypeListAsString + SortTypeList[i].Name;
  end;
end.
