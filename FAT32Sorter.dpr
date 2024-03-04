program FAT32Sorter;

uses
  FastMM5,
  Vcl.Forms,
  frmMain in 'frmMain.pas' {MainForm},
  frmSort in 'frmSort.pas' {SortForm},
  frSortPanel in 'frSortPanel.pas' {SortFrame: TFrame},
  frmRename in 'frmRename.pas' {RenameForm},
  FAT32Struct in 'FAT32Struct.pas',
  FAT32 in 'FAT32.pas',
  ID3Struct in 'ID3Struct.pas',
  ID3 in 'ID3.pas',
  FileReader in 'FileReader.pas',
  FileSorter in 'FileSorter.pas',
  uMessageDlg in 'uMessageDlg.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'FAT32 Sorter';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
