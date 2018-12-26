/*
 *  The scanner definition for COOL.
 */

import java_cup.runtime.Symbol;
import java.util.*;

%%

%{

/*  Stuff enclosed in %{ %} is copied verbatim to the lexer class
 *  definition, all the extra variables/functions you want to use in the
 *  lexer actions should go here.  Don't remove or modify anything that
 *  was there initially.  */

    // Max size of string constants
    static int MAX_STR_CONST = 1025;

    // For assembling string constants
    StringBuffer string_buf = new StringBuffer();

    private int curr_lineno = 1;
    int get_curr_lineno() {
		curr_lineno = yyline + 1;
		return curr_lineno;
    }

    private AbstractSymbol filename;

    void set_filename(String fname) {
		filename = AbstractTable.stringtable.addString(fname);
    }

    AbstractSymbol curr_filename() {
		return filename;
    }

    private Map<String,Integer> idMap = new HashMap<>();
    private Map<String,Integer> stringMap = new HashMap<>();
    private Map<String,Integer> numberMap = new HashMap<>();

	private int commentLv = 0 ; //for nested multi-line comment
    private boolean eof = false  ;
	private boolean nullInString = false;
%}

%init{

/*  Stuff enclosed in %init{ %init} is copied verbatim to the lexer
 *  class constructor, all the extra initialization you want to do should
 *  go here.  Don't remove or modify anything that was there initially. */

    // empty for now

%init}

%eofval{

/*  Stuff enclosed in %eofval{ %eofval} specifies java code that is
 *  executed when end-of-file is reached.  If you use multiple lexical
 *  states and want to do something special if an EOF is encountered in
 *  one of those states, place your code in the switch statement.
 *  Ultimately, you should return the EOF symbol, or your lexer won't
 *  work.  */

    if(!eof){
    	Symbol s = 	new Symbol(TokenConstants.ERROR);
        switch(yy_lexical_state) {
		    case COMMENT:
                eof = true;
                s.value = "EOF in comment"; 
                return s;
		    case STRING:
            case STRING_ESCAPE:
                eof = true;
                s.value = "EOF in string constant"; 
                return s;
         }
         eof = true;
    }

    return new Symbol(TokenConstants.EOF);
   
%eofval}

%class CoolLexer
%cup
%line
%state COMMENT,SINGLE_COMMENT,ID,STRING,STRING_ESCAPE
%notunix
%unicode

DIGIT=[0-9]
NUMBER=({DIGIT}+)
NEWLINE=\r\n|\n
WHITESPACE=[ \t\f\v\r]
SEP=(({WHITESPACE}|{NEWLINE})*)
KEYWORDS=([cC][lL][aA][sS][sS]|[eE][lL][sS][eE]|f[aA][lL][sS][eE]|[fF][iI]|[iI][fF]|[iI][nN]|[iI][nN][hH][eE][rR][iI][tT][sS]|[iI][sS][vV][oO][iI][dD]|[lL][eE][tT]|[lL][oO][oO][pP]|[pP][oO][oO][lL]|[tT][hH][eE][nN]|[wW][hH][iI][lL][eE]|[cC][aA][sS][eE]|[eE][sS][aA][cC]|[nN][eE][wW]|[oO][fF]|[nN][oO][tT]|t[rR][uU][eE]) 
ANY=.|{NEWLINE}
LETTERS=[a-zA-Z]
ID={LETTERS}({LETTERS}|{DIGIT}|_)*
BACK_SLASH_AND_NEW_LINE=\\{NEWLINE}
BACK_SLASH=\\

%%

<YYINITIAL> "(*" {
    yybegin(COMMENT);
	commentLv++;
}
<COMMENT> "(*" {
	commentLv++;
}
<COMMENT> "*)" {
	commentLv--;
	if(commentLv == 0){
		yybegin(YYINITIAL);
	}
}
<COMMENT> {NEWLINE} {
}

<COMMENT> {ANY} {
}

<YYINITIAL> "--" {
	yybegin(SINGLE_COMMENT);
}

<SINGLE_COMMENT> {NEWLINE} {
	yybegin(YYINITIAL);
}
<SINGLE_COMMENT> . {
}

<YYINITIAL> "\"" {
	yybegin(STRING);
}

<STRING> "\"" {
	String text = string_buf.toString();
	string_buf.setLength(0); 
	yybegin(YYINITIAL);

	if(!nullInString){
		if(text.length()==1025){
			Symbol s = new Symbol(TokenConstants.ERROR); 
			s.value = "String constant too long";
			return s;
		}else if(text.length()>1025){
			Symbol s = new Symbol(TokenConstants.ERROR); 
			s.value = "String constant too long";
			return s;
		}
		int index = 0;		
		if(stringMap.containsKey(text)){
			index = stringMap.get(text);
		}else{
			index = stringMap.size();
			stringMap.put(text,index);
		}
		Symbol s = new Symbol(TokenConstants.STR_CONST);
		s.value = new StringSymbol(text,text.length(),index);
		return s;
	}
}

<STRING> {BACK_SLASH} {
	yybegin(STRING_ESCAPE);
}

<STRING> \0 {
	yybegin(STRING);
	string_buf.setLength(0);
	nullInString = true;
	Symbol s = new Symbol(TokenConstants.ERROR); 
	s.value = "String contains escaped null character.";
	return s;
}


<STRING_ESCAPE> \0 {
	yybegin(STRING);
	string_buf.setLength(0);
	nullInString = true;
	Symbol s = new Symbol(TokenConstants.ERROR); 
	s.value = "String contains escaped null character.";
	return s;
}


<STRING_ESCAPE> "n" {
	string_buf.append("\n");
	yybegin(STRING);
}
<STRING_ESCAPE> "b" {
	string_buf.append("\b");
	yybegin(STRING);
}
<STRING_ESCAPE> "t" {
	string_buf.append("\t");
	yybegin(STRING);
}
<STRING_ESCAPE> "f" {
	string_buf.append("\f");
	yybegin(STRING);
}
<STRING_ESCAPE> "\"" {
	string_buf.append("\"");
	yybegin(STRING);
}

<STRING_ESCAPE> {BACK_SLASH} {
	string_buf.append("\\");
	yybegin(STRING);
}


<STRING_ESCAPE> {NEWLINE} {
    string_buf.append("\n");
	yybegin(STRING);
}

<STRING_ESCAPE> . {
	string_buf.append(yytext());
    yybegin(STRING);
}

<STRING> {NEWLINE} {
    string_buf.setLength(0);
	yybegin(YYINITIAL);
	if(!nullInString){
		Symbol s = 	new Symbol(TokenConstants.ERROR); 	
		s.value = "Unterminated string constant";
		return s;
	}else{
		nullInString = false;
	}
}

<STRING> \015 {
	string_buf.append(yytext());
}


<STRING> . {
	string_buf.append(yytext());
}

<YYINITIAL> {NUMBER} {
	String text = yytext();
	int index = 0;
    if(numberMap.containsKey(text)){
		index = numberMap.get(text);
	}else{
		index = stringMap.size();
		numberMap.put(text,index);
	}
    Symbol s = new Symbol(TokenConstants.INT_CONST);
	s.value = new IntSymbol(text,text.length(),index);
	return s;

}

{WHITESPACE} {
}

\013 {
}

<YYINITIAL> {NEWLINE} {
}

<YYINITIAL> {KEYWORDS} {
	String keyword = yytext();
	keyword=keyword.trim().toLowerCase();
	switch(keyword){
		case "class": return new Symbol(TokenConstants.CLASS);
		case "else": return new Symbol(TokenConstants.ELSE);
		case "if": return new Symbol(TokenConstants.IF);
		case "fi": return new Symbol(TokenConstants.FI);
		case "in": return new Symbol(TokenConstants.IN);
		case "inherits": return new Symbol(TokenConstants.INHERITS);
		case "isvoid": return new Symbol(TokenConstants.ISVOID);
		case "let": return new Symbol(TokenConstants.LET);
		case "loop": return new Symbol(TokenConstants.LOOP);
		case "pool": return new Symbol(TokenConstants.POOL);
		case "then": return new Symbol(TokenConstants.THEN);
		case "while": return new Symbol(TokenConstants.WHILE);
		case "case": return new Symbol(TokenConstants.CASE);
		case "esac": return new Symbol(TokenConstants.ESAC);
		case "new": return new Symbol(TokenConstants.NEW);
		case "of": return new Symbol(TokenConstants.OF);
		case "not": return new Symbol(TokenConstants.NOT);
		case "true":
			 Symbol t = new Symbol(TokenConstants.BOOL_CONST);
			 t.value = true;
			 return  t;
		case "false":
			 Symbol f = new Symbol(TokenConstants.BOOL_CONST);
			 f.value = false;
			 return f;

	}
}	


<YYINITIAL> {ID} {
	String text = yytext();
	char c = text.charAt(0);

	if( (c>=65 && c<=90 )|| (c>=97 && c<=122) ){
		int index =0;		
        if(idMap.containsKey(text)){
			index = idMap.get(text);
		}else{
			index = idMap.size();
			idMap.put(text,index);
		}
        IdTable t = new IdTable();
		Symbol s ;
		if(c>=65 && c<=90){ //cap
			s = new Symbol(TokenConstants.TYPEID); 
		        s.value = t.getNewSymbol(text,text.length(),index);
			return s; 
		}else{ //lowercase
			s= new Symbol(TokenConstants.OBJECTID); 
			s.value = t.getNewSymbol(text,text.length(),index);
			return s; 
		}
	}else{
		System.err.println("err id:"+text); 
	}
}

<YYINITIAL>"*)" {
	Symbol s = new Symbol(TokenConstants.ERROR); 
	s.value = "Unmatched "+yytext();	
	return s;
}
<YYINITIAL>"{" {
   return new Symbol(TokenConstants.LBRACE); 	
}
<YYINITIAL>"}" {
   return new Symbol(TokenConstants.RBRACE); 	
}
<YYINITIAL>"(" {
   return new Symbol(TokenConstants.LPAREN); 	
}
<YYINITIAL>")" {
   return new Symbol(TokenConstants.RPAREN); 	
}
<YYINITIAL>":" {
   return new Symbol(TokenConstants.COLON); 	
}
<YYINITIAL>";" {
   return new Symbol(TokenConstants.SEMI); 	
}
<YYINITIAL>"<-" {
   return new Symbol(TokenConstants.ASSIGN); 	
}
<YYINITIAL>"<=" {
   return new Symbol(TokenConstants.LE);
}
<YYINITIAL>"=>"	{ 
  return new Symbol(TokenConstants.DARROW); 
}
<YYINITIAL>"," {
   return new Symbol(TokenConstants.COMMA); 	
}
<YYINITIAL>"=" {
   return new Symbol(TokenConstants.EQ); 	
}
<YYINITIAL>"+" {
   return new Symbol(TokenConstants.PLUS); 	
}
<YYINITIAL>"-" {
   return new Symbol(TokenConstants.MINUS); 	
}
<YYINITIAL>"*" {
   return new Symbol(TokenConstants.MULT); 	
}
<YYINITIAL>"/" {
   return new Symbol(TokenConstants.DIV); 	
}
<YYINITIAL>"~" {
   return new Symbol(TokenConstants.NEG);
}
<YYINITIAL>"." {
   return new Symbol(TokenConstants.DOT); 	
}
<YYINITIAL>"@" {
   return new Symbol(TokenConstants.AT); 	
}
<YYINITIAL>"<" {
   return new Symbol(TokenConstants.LT);
}
. { 
	Symbol s = 	new Symbol(TokenConstants.ERROR); 
	s.value = yytext();
	return s;

}
