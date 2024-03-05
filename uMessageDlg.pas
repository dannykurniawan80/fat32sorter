{ ============================================================================
    File Name   : uMessageDlg.pas
    Author      : Danny Kurniawan <danny.kurniawan@gmail.com>
    Description : Message Dialog that centered to either MainForm or custom form
    License     : GPLv3
  ============================================================================ }
unit uMessageDlg;

interface

uses
  Forms, Dialogs;


function ShowMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Integer = 0): Integer; overload;

function ShowMessageDlg(const AOwner: TForm; const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Integer = 0): Integer; overload;


implementation


function ShowMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Integer = 0): Integer;
begin
  Result := ShowMessageDlg(Application.MainForm, Msg, DlgType, Buttons, HelpCtx);
end;

function ShowMessageDlg(const AOwner: TForm; const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Integer = 0): Integer;
begin
  with CreateMessageDialog(Msg, DlgType, Buttons) do
    try
      Left := AOwner.Left + (AOwner.Width - Width) div 2;
      Top := AOwner.Top + (AOwner.Height - Height) div 2;
      Result := ShowModal;
    finally
      Free;
    end;
end;


end.
