{ ============================================================================
    File Name   : frSortPanel.pas
    Author      : Danny Kurniawan <danny.kurniawan@gmail.com>
    Description : UI Frame for custom sort entries
    License     : GPLv3
  ============================================================================ }
unit frSortPanel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.Samples.Spin;

type
  TSortFrame = class(TFrame)
    cbSelect: TCheckBox;
    lblSortBy: TLabel;
    cbbSortBy: TComboBox;
    cbbSortDirection: TComboBox;
    cbCaseInsensitive: TCheckBox;
    sbtnUpDown: TSpinButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

end.
