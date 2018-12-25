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
	return curr_lineno;
    }

    private AbstractSymbol filename;

    void set_filename(String fname) {
	filename = AbstractTable.stringtable.addString(fname);
    }

    AbstractSymbol curr_filename() {
	return filename;
    }

    boolean isLastWhite = false;
    boolean start = false;
    private int idTableIndex =0;
//    private List<String> idList = new ArrayList<>();

    private Map<String,Integer> idMap = new HashMap<>();

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

    switch(yy_lexical_state) {
    case YYINITIAL:
	/* nothing special to do in the initial state */
	break;
	/* If necessary, add code for other states here, e.g:
	   case COMMENT:
	   ...
	   break;
	*/
    }
    return new Symbol(TokenConstants.EOF);
%eofval}

%class CoolLexer
%cup
%line
%state COMMENT,ID,STRING,STRING_ESCAPE
%notunix

DIGIT=[0-9]

NEWLINE=\n|\r\n
KEYWORDS=(class|else|false|fi|if|in|inherits|isvoid|let|loop|pool|then|while|case|esac|new|of|not|true)
ANY=.|{NEWLINE}
WHITESPACE=[ \t]
SEP=({WHITESPACE}|{NEWLINE})+
LETTERS=[a-zA-Z]
ID={LETTERS}({LETTERS}|{DIGIT}|_)*
BACK_SLASH_AND_NEW_LINE=\\{NEWLINE}
BACK_SLASH=\\

%%

<YYINITIAL> "(*" {
	//System.out.println("comment begin.");
	yybegin(COMMENT);
}

<COMMENT> "*)" {
//	System.out.println("comment finish.");
	yybegin(YYINITIAL);
}



<COMMENT> {ANY} {
//	System.out.println("comment:"+yytext());
}

<YYINITIAL> "\"" {
//	System.out.println("String start.");
	yybegin(STRING);
}

<STRING> "\"" {
//	System.out.println("String end.");
	yybegin(YYINITIAL);
}

<STRING> {BACK_SLASH_AND_NEW_LINE}  {
	System.out.println("wrapped String........");
}

<STRING> {BACK_SLASH} {
	yybegin(STRING_ESCAPE);
}

<STRING_ESCAPE> "n\"" {
        System.out.println("********  String \\n   *******");
        yybegin(YYINITIAL);
}
<STRING_ESCAPE> "b\"" {
        System.out.println("********  String \\b   *******");
        yybegin(YYINITIAL);
}
<STRING_ESCAPE> "t\"" {
        System.out.println("********  String \\t   *******");
        yybegin(YYINITIAL);
}
<STRING_ESCAPE> "f\"" {
        System.out.println("********  String \\f   *******");
        yybegin(YYINITIAL);
}





<STRING> {NEWLINE} {
          System.out.println("******** ERROR:new line in string *******");
}

<STRING> . {
	System.out.println("char:"+yytext());
}

<YYINITIAL> {SEP} {}
<YYINITIAL> {NEWLINE} {}

<YYINITIAL> {SEP}{KEYWORDS}{SEP} {
	String keyword = yytext();
	curr_lineno = yyline+1;
	if(keyword.startsWith("\n")){
		curr_lineno++;	
	}
	keyword=keyword.trim();
	switch(keyword){
		case "class":
		    return new Symbol(TokenConstants.CLASS);
		case "else": return new Symbol(TokenConstants.ELSE);
		case "if": return new Symbol(TokenConstants.IF);
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
	}
}	


<YYINITIAL> {ID} {
	curr_lineno = yyline+1;
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
	}
	else{
		System.err.println("err id:"+text); 
	}
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

<YYINITIAL>"=>"			{ /* Sample lexical rule for "=>" arrow.
                                     Further lexical rules should be defined
                                     here, after the last %% separator */
                                  return new Symbol(TokenConstants.DARROW); 
}

.                               { /* This rule should be the very last
                                     in your lexical specification and
                                     will match match everything not
                                     matched by other lexical rules. */

                                  System.err.println("******** LEXER BUG - UNMATCHED: " + +(yyline+1)+ ":" + yytext()+"********"); 
//System.exit(0);
}

