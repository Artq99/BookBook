unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  ActnList, StdCtrls, ExtCtrls, fgl, laz2_DOM, laz2_XMLRead, laz2_XMLWrite;

type

  { TBook -----------------------------------------------------------------------------------------}

  TBook = class(TObject)
  private
    FTitle, FAuthor: ansistring;
    FR: boolean;
  public
    constructor Create(const ATitle, AAuthor: ansistring; const AR: boolean = false);
    property Title: ansistring read FTitle write FTitle;
    property Author: ansistring read FAuthor write FAuthor;
    property R: boolean read FR write FR;
    function GetNode(var Document: TXMLDocument): TDOMNode;
  end;

  { TBookList -------------------------------------------------------------------------------------}

  TBookList = specialize TFPGObjectList<TBook>;

  { TFormBookBook ---------------------------------------------------------------------------------}

  TFormBookBook = class(TForm)
    ActionRemoveBook: TAction;
    ActionAddBook: TAction;
    ActionSaveToXML: TAction;
    ActionLoadList: TAction;
    ActionLoadFromXML: TAction;
    ActionList: TActionList;
    ButtonApplyChanges: TButton;
    ButtonAddBook: TButton;
    ButtonRemoveBook: TButton;
    ButtonGetRandomBook: TButton;
    CheckBoxNotReadOnly: TCheckBox;
    CheckBoxRead: TCheckBox;
    ComboBoxSorting: TComboBox;
    GroupBoxStats: TGroupBox;
    GroupBoxBookDetails: TGroupBox;
    LabelBooksTotalValue: TLabel;
    LabelBooksReadValue: TLabel;
    LabelBooksUnreadValue: TLabel;
    LabelBooksPercentageValue: TLabel;
    LabelBooksUnread: TLabel;
    LabelBooksTotal: TLabel;
    LabelBooksRead: TLabel;
    LabelBooksPercentage: TLabel;
    LabeledEditTitle: TLabeledEdit;
    LabeledEditAuthor: TLabeledEdit;
    LabelSorting: TLabel;
    ListBoxBooks: TListBox;
    MainMenu: TMainMenu;
    MenuItemRemoveBook: TMenuItem;
    MenuItemAddBook: TMenuItem;
    MenuItemEdit: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuItemSep1: TMenuItem;
    MenuItemSaveChanges: TMenuItem;
    MenuItemFile: TMenuItem;
    procedure ActionAddBookExecute(Sender: TObject);
    procedure ActionLoadFromXMLExecute(Sender: TObject);
    procedure ActionLoadListExecute(Sender: TObject);
    procedure ActionRemoveBookExecute(Sender: TObject);
    procedure ActionSaveToXMLExecute(Sender: TObject);
    procedure ButtonApplyChangesClick(Sender: TObject);
    procedure ButtonGetRandomBookClick(Sender: TObject);
    procedure ComboBoxSortingChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListBoxBooksSelectionChange(Sender: TObject; User: boolean);
    procedure MenuItemExitClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    BookList: TBookList;
  end;

const
  DBPath: string = 'DB.xml';

var
  FormBookBook: TFormBookBook;

{==================================================================================================}
implementation

{ TFormBookBook }

procedure TFormBookBook.FormCreate(Sender: TObject);
begin
  Randomize;
  Self.BookList := TBookList.Create;
  Self.ActionLoadFromXMLExecute(Self);
  Self.ActionLoadListExecute(Self);
end;

procedure TFormBookBook.ActionLoadFromXMLExecute(Sender: TObject);
var
  Doc: TXMLDocument;
  Node: TDOMNode;
  Title, Author: ansistring;
  R: boolean;
begin
  if not FileExists(DBPath) then exit;
  try
    ReadXMLFile(Doc, DBPath);
    Node := Doc.DocumentElement.FirstChild;
    while Assigned(Node) do
    begin
      Title := UTF8Encode(Node.Attributes.GetNamedItem('title').NodeValue);
      Author := UTF8Encode(Node.Attributes.GetNamedItem('author').NodeValue);
      R := StrToBool(Node.Attributes.GetNamedItem('read').NodeValue);
      Self.BookList.Add(TBook.Create(Title, Author, R));
      Node := Node.NextSibling;
    end;
  finally
    Doc.Free;
  end;
end;

procedure TFormBookBook.ActionAddBookExecute(Sender: TObject);
begin
  Self.BookList.Add(TBook.Create('Brak tytułu', 'Brak autora'));
  Self.ActionLoadListExecute(Self);
  Self.ListBoxBooks.ItemIndex := Self.ListBoxBooks.Count - 1;
end;

procedure TFormBookBook.ActionLoadListExecute(Sender: TObject);
var
  BooksTotal, BooksRead, BooksUnread, BooksPercentage, i, j: integer;
begin
  Self.ListBoxBooks.Clear;
  for i := 0 to Self.BookList.Count -1 do
  begin
    Self.ListBoxBooks.Items.Add(
                                IntToStr(i + 1) +
                                '. ' +
                                Self.BookList[i].Title +
                                ' - ' +
                                Self.BookList[i].Author);
    BooksTotal := Self.BookList.Count;
    BooksRead := 0;
    for j := 0 to BooksTotal - 1 do
    begin
      if Self.BookList[j].R then Inc(BooksRead);
    end;
    BooksUnread := BooksTotal - BooksRead;
    BooksPercentage := Round(BooksRead / BooksTotal * 100);

    Self.LabelBooksTotalValue.Caption := IntToStr(BooksTotal);
    Self.LabelBooksReadValue.Caption := IntToStr(BooksRead);
    Self.LabelBooksUnreadValue.Caption := IntToStr(BooksUnread);
    Self.LabelBooksPercentageValue.Caption := IntToStr(BooksPercentage) + '%';
  end;
end;

procedure TFormBookBook.ActionRemoveBookExecute(Sender: TObject);
var
  Index: integer;
begin
  Index := Self.ListBoxBooks.ItemIndex;
  if Index <> -1 then
  begin
    Self.BookList.Delete(Index);
    Self.ActionLoadListExecute(Self);
  end;
end;

procedure TFormBookBook.ActionSaveToXMLExecute(Sender: TObject);
var
  Doc: TXMLDocument;
  RootNode: TDOMNode;
  i: integer;
begin
  try
    Doc := TXMLDocument.Create;
    RootNode := Doc.CreateElement('root');
    Doc.AppendChild(RootNode);
    for i := 0 to Self.BookList.Count - 1 do
    begin
      RootNode.AppendChild(Self.BookList[i].GetNode(Doc));
    end;
    WriteXMLFile(Doc, 'DB.xml');
  finally
    Doc.Free;
  end;
end;

procedure TFormBookBook.ButtonApplyChangesClick(Sender: TObject);
var
  Index: integer;
begin
  Index := Self.ListBoxBooks.ItemIndex;
  if Index <> -1 then
  begin
    Self.BookList[Index].Title := Self.LabeledEditTitle.Text;
    Self.BookList[Index].Author := Self.LabeledEditAuthor.Text;
    Self.BookList[Index].R := Self.CheckBoxRead.Checked;
    Self.ActionLoadListExecute(Self);
  end;
end;

procedure TFormBookBook.ButtonGetRandomBookClick(Sender: TObject);
var
  Pick, i: integer;
  UnreadBooksOnList: boolean;
begin
  if not Self.CheckBoxNotReadOnly.Checked then
  begin;
    Pick := Random(Self.BookList.Count);
    ShowMessage(Self.BookList[Pick].Title + ' - ' + Self.BookList[Pick].Author);
  end
  else
  begin
    UnreadBooksOnList := false;
    for i := 0 to Self.BookList.Count -1 do
    begin
      if Self.BookList[i].R = false then UnreadBooksOnList := true;
    end;
    if not UnreadBooksOnList then ShowMessage('Na liście nie ma nieprzeczytanych książek!')
    else
    begin
      repeat
        Pick := Random(Self.BookList.Count);
      until Self.BookList[Pick].R = false;
      ShowMessage(Self.BookList[Pick].Title + ' - ' + Self.BookList[Pick].Author);
    end;
  end;
end;

procedure TFormBookBook.ComboBoxSortingChange(Sender: TObject);
var
  i: integer;
  Sorting, TempStr1, TempStr2: ansistring;
begin
  Sorting := Self.ComboBoxSorting.Text;
  if Sorting <> 'Wybierz' then
  begin
    i := 0;
    repeat
      if Sorting = 'Tytuł' then
      begin
        TempStr1 := UpperCase(Self.BookList[i].Title);
        TempStr2 := UpperCase(Self.BookList[i + 1].Title);
      end
      else if Sorting = 'Autor' then
      begin
        TempStr1 := UpperCase(Self.BookList[i].Author);
        TempStr2 := UpperCase(Self.BookList[i + 1].Author);
      end;
      if TempStr1[1] > TempStr2[1] then
      begin
        Self.BookList.Exchange(i, i + 1);
        i := -1;
      end;
      Inc(i);
    until i = Self.BookList.Count - 1;
    Self.ComboBoxSorting.Text := 'Wybierz';
    Self.ActionLoadListExecute(Self);
  end;
end;

procedure TFormBookBook.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  if MessageDlg('Wyjście', 'Czy chcesz zapisać zmiany?', mtConfirmation, [mbYes, mbNo], 0) = mrYes
  then Self.ActionSaveToXMLExecute(Self);
end;

procedure TFormBookBook.FormDestroy(Sender: TObject);
begin
  Self.BookList.Free;
end;

procedure TFormBookBook.ListBoxBooksSelectionChange(Sender: TObject; User: boolean);
var
  Index: integer;
begin
  Index := Self.ListBoxBooks.ItemIndex;
  if Index <> -1 then
  begin
    Self.LabeledEditTitle.Text := Self.BookList[Index].Title;
    Self.LabeledEditAuthor.Text := Self.BookList[Index].Author;
    Self.CheckBoxRead.Checked := Self.BookList[Index].R;
  end;
end;

procedure TFormBookBook.MenuItemExitClick(Sender: TObject);
begin
  Self.Close;
end;

{==================================================================================================}

{$R *.lfm}

{ TBook -------------------------------------------------------------------------------------------}

constructor TBook.Create(const ATitle, AAuthor: ansistring; const AR: boolean = false);
begin
  inherited Create;
  Self.FTitle := ATitle;
  Self.FAuthor := AAuthor;
  Self.FR := AR;
end;

function TBook.GetNode(var Document: TXMLDocument): TDOMNode;
begin
  Result := Document.CreateElement('book');
  TDOMElement(Result).SetAttribute('title', Self.Title);
  TDOMElement(Result).SetAttribute('author', Self.Author);
  TDOMElement(Result).SetAttribute('read', BoolToStr(Self.R));
end;

end.

