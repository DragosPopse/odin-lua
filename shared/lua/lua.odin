package lua

import "core:os"
import "core:c"
import "core:strings" // see pushstring

@private 
DIGITS :: [?]string {
	0 = "0",
	1 = "1",
	2 = "2", 
	3 = "3",
	4 = "4",
	5 = "5",
	6 = "6",
	7 = "7",
	8 = "8",
	9 = "9",
}

JIT_ENABLED :: #config(LUA_JIT, false)
OVERRIDE_LIB :: #config(LUA_OVERRIDE_LIB, false)
when  JIT_ENABLED {
	MAJOR_VERSION :: 5
	MINOR_VERSION :: 1
	RELEASE_VERSION :: 4
} else {
	MAJOR_VERSION :: #config(LUA_MAJOR, 5)
	MINOR_VERSION :: #config(LUA_MINOR, 4)
	RELEASE_VERSION :: #config(LUA_RELEASE, 2)
}

when OVERRIDE_LIB {
	when os.OS == .Windows do foreign import liblua "lualib:lua.lib" 
	else do foreign import liblua "lualib:lua"
} else {
	when os.OS == .Windows do foreign import liblua "windows/lua542.lib"
	when os.OS == .Linux do foreign import liblua "system:lua"
	when os.OS == .Darwin do foreign import liblua "system:lua"
}


VERSION_MAJOR :: DIGITS[MAJOR_VERSION]
VERSION_MINOR :: DIGITS[MINOR_VERSION]
VERSION_RELEASE ::	DIGITS[RELEASE_VERSION]
VERSION_NUM :: MAJOR_VERSION * 100 + MINOR_VERSION
VERSION ::	"Lua " + VERSION_MAJOR + "." + VERSION_MINOR
RELEASE ::	VERSION + "." + VERSION_RELEASE

COPYRIGHT ::	RELEASE + "  Copyright (C) 1994-2018 Lua.org, PUC-Rio"
AUTHORS ::	"R. Ierusalimschy, L. H. de Figueiredo, W. Celes"

SIGNATURE :: "\x1bLua"
MULTRET	:: (-1)

NUMBER :: c.double
INTEGER :: c.longlong
KCONTEXT :: c.ptrdiff_t
IDSIZE :: 60
UNSIGNED :: u64
MAXSTACK :: 1000000
EXTRASPACE :: size_of(rawptr)

Number :: NUMBER
Integer :: INTEGER
Unsigned :: UNSIGNED
KContext :: KCONTEXT

when !JIT_ENABLED { REGISTRYINDEX :: (-MAXSTACK - 1000) }

OK 			:: 0
YIELD 		:: 1
ERRRUN 		:: 2
ERRSYNTAX 	:: 3
ERRMEM 		:: 4
ERRGCMM 	:: 5
ERRERR 		:: 6

TNONE 				::	(-1)
TNIL 				::	0
TBOOLEAN 			::	1
TLIGHTUSERDATA 		::	2
TNUMBER 			::	3
TSTRING 			::	4
TTABLE 				::	5
TFUNCTION 			::	6
TUSERDATA 			::	7
TTHREAD 			::	8
NUMTAGS 			::	9
MINSTACK 			::	20

RIDX_MAINTHREAD 		::	1
RIDX_GLOBALS 			::	2
RIDX_LAST 				:: RIDX_GLOBALS
OPADD :: 0
OPSUB :: 1
OPMUL :: 2
OPMOD :: 3
OPPOW :: 4
OPDIV :: 5
OPIDIV :: 6
OPBAND :: 7
OPBOR :: 8
OPBXOR :: 9
OPSHL :: 10
OPSHR :: 11
OPUNM :: 12
OPBNOT :: 13

OPEQ ::	0
OPLT ::	1
OPLE ::	2

GCSTOP 			:: 0
GCRESTART 		:: 1
GCCOLLECT 		:: 2
GCCOUNT 		:: 3
GCCOUNTB 		:: 4
GCSTEP 			:: 5
GCSETPAUSE 		:: 6
GCSETSTEPMUL	:: 7
GCISRUNNING 	:: 9

HOOKCALL 		:: 0
HOOKRET 		:: 1
HOOKLINE 		:: 2
HOOKCOUNT 		:: 3
HOOKTAILCALL 	:: 4

MASKCALL :: (1 << HOOKCALL)
MASKRET :: (1 << HOOKRET)
MASKLINE :: (1 << HOOKLINE)
MASKCOUNT :: (1 << HOOKCOUNT)

ERRFILE :: (ERRERR+1)
LOADED_TABLE :: "_LOADED"
PRELOAD_TABLE :: "_PRELOAD"


NOREF :: -2
REFNIL :: -1

/*
	TYPES
*/
CFunction :: #type proc "c" (L: ^State ) -> c.int
KFunction :: #type proc "c" (L: ^State , status: c.int , ctx:KContext) -> c.int
Reader :: #type proc "c" (L: ^State , ud: rawptr , sz: ^c.ptrdiff_t) -> cstring
Writer :: #type proc "c" (L: ^State , p: cstring, sz:c.ptrdiff_t , ud:rawptr) -> c.int 
Hook :: #type proc "c" (L: ^State , ar: ^Debug )
Alloc :: #type proc "c" (ud: rawptr, ptr: rawptr, osize:c.ptrdiff_t, nsize:c.ptrdiff_t) -> rawptr

// lua_ident: ^u8;

State :: struct{}


CallInfo :: struct {}

Debug :: struct {
	event : c.int,
	name : cstring,	
	namewhat: cstring,
	what: cstring,
	source: cstring,
	currentline: c.int ,
	linedefined: c.int ,	
	lastlinedefined: c.int ,
	nups: u8,	
	nparams: u8,
	isvararg: i8,
	istailcall: i8,
	short_src: [IDSIZE]i8,
	/* private part */
	i_ci : ^CallInfo ,  
}






@(default_calling_convention = "c")
@(link_prefix = "lua_")
foreign liblua {
	// lua_pushfstring :: proc (L: ^State , fmt: cstring , ...) -> cstring ---;
	// lua_pushvfstring :: proc (L: ^State , fmt: cstring , va_list argp) -> cstring ---;

	absindex :: proc (L: ^State , idx: c.int ) -> c.int ---
	arith :: proc (L: ^State , op: c.int ) ---
	atpanic :: proc (L: ^State ,  panicf: CFunction) -> CFunction ---
	callk :: proc (L: ^State , nargs: c.int, nresults: c.int, ctx: KContext , k: KFunction ) ---
	checkstack :: proc (L: ^State , n: c.int ) -> c.int ---
	close :: proc (L: ^State ) ---
	compare :: proc (L: ^State ,  idx1: c.int,  idx2: c.int,  op: c.int) -> c.int ---
	concat :: proc (L: ^State , n: c.int) ---
	copy :: proc (L: ^State , fromidx: c.int , toidx: c.int ) ---
	createtable :: proc (L: ^State , narr: c.int , nrec: c.int ) ---
	dump :: proc (L: ^State , writer: Writer , data: rawptr, strip:c.int) -> c.int ---
	error :: proc (L: ^State ) -> c.int ---
	gc :: proc (L: ^State , what: c.int, data: c.int) -> c.int ---
	getallocf :: proc (L: ^State , ud: ^rawptr ) -> c.int ---
	getfield :: proc (L: ^State , idx: c.int , k: cstring) -> c.int ---

	gethook :: proc (L: ^State ) -> Hook ---
	gethookcount :: proc(L: ^State ) -> c.int ---
	gethookmask :: proc (L: ^State ) -> c.int ---
	geti :: proc (L: ^State , idx: c.int , n: Integer) -> c.int ---
	getinfo :: proc (L: ^State , what: cstring, ar: ^Debug ) -> c.int ---
	getlocal :: proc (L: ^State , ar: ^Debug , n: c.int) -> cstring ---
	getmetatable :: proc (L: ^State , objindex:c.int ) -> c.int ---
	getstack :: proc (L: ^State ,  level: c.int, ar: ^Debug) -> c.int --- 
	gettable :: proc (L: ^State , idx: c.int ) -> c.int ---
	gettop :: proc (L: ^State ) -> c.int ---
	getupvalue :: proc (L: ^State , funcindex: c.int , n: c.int) -> cstring ---
	getuservalue :: proc (L: ^State , idx: c.int ) -> c.int ---
	iscfunction :: proc (L: ^State , idx: c.int ) -> c.int ---
	isinteger :: proc (L: ^State , idx: c.int ) -> c.int ---
	isnumber :: proc (L: ^State , idx: c.int ) -> c.int ---
	isstring :: proc (L: ^State , idx: c.int ) -> c.int ---
	isuserdata :: proc (L: ^State , idx: c.int ) -> c.int ---
	isyieldable :: proc (L: ^State ) -> c.int ---
	len :: proc (L: ^State , idx: c.int) ---
	load :: proc (L: ^State , reader: Reader, dt: rawptr, chunkname: cstring, mode: cstring) -> c.int --- 
	newstate :: proc (f: Alloc, ud :rawptr) -> ^State ---
	newthread :: proc (L: ^State ) -> ^State ---
	newuserdatauv :: proc (L: ^State, sz: c.ptrdiff_t, nuvalue: c.int) -> rawptr ---
	next :: proc (L: ^State , idx: c.int) -> c.int ---
	pcallk :: proc (L: ^State , nargs: c.int, nresults: c.int, errfunc: c.int, ctx: KContext , k: KFunction ) -> c.int  ---
	pushboolean :: proc (L: ^State , b: c.bool ) ---
	pushcclosure :: proc (L: ^State , fn: CFunction, n:c.int) ---
	pushinteger :: proc (L: ^State , n: Integer ) ---
	pushlightuserdata :: proc (L: ^State , p: rawptr) ---
	pushlstring :: proc (L: ^State , s: cstring, len: c.ptrdiff_t) -> cstring ---
	pushnil :: proc (L: ^State ) ---
	pushnumber :: proc (L: ^State ,  n: Number) ---
	
	pushthread :: proc (L: ^State ) -> c.int ---
	pushvalue :: proc (L: ^State , idx:c.int ) ---
	rawequal :: proc (L: ^State ,  idx1: c.int,  idx2: c.int) -> c.int ---
	rawget :: proc (L: ^State , idx: c.int ) -> c.int ---
	rawgeti :: proc (L: ^State , idx: c.int , n: Integer) -> c.int ---
	rawgetp :: proc (L: ^State , idx: c.int , p: rawptr) -> c.int ---
	rawlen :: proc (L: ^State , idx: c.int ) -> c.ptrdiff_t ---
	rawset :: proc (L: ^State , idx: c.int ) ---
	rawseti :: proc (L: ^State , idx: c.int , n: Integer) ---
	rawsetp :: proc (L: ^State , idx: c.int , p: rawptr) ---
	resume :: proc (L: ^State , from: ^State, narg: c.int) -> c.int ---
	rotate :: proc (L: ^State , idx:c.int , n:c.int) ---
	setallocf :: proc (L: ^State , f: Alloc , ud: rawptr ) ---
	setfield :: proc (L: ^State , idx: c.int , k: cstring) ---

	sethook :: proc (L: ^State , func: Hook , mask: c.int, count: c.int ) ---
	seti :: proc (L: ^State , idx: c.int , n: Integer) ---
	setlocal :: proc (L: ^State , ar: ^Debug , n: c.int) -> cstring ---
	setmetatable :: proc (L: ^State , objindex: c.int ) -> c.int ---
	settable :: proc (L: ^State , idx: c.int ) ---
	settop :: proc (L: ^State , idx:c.int ) ---
	setupvalue :: proc (L: ^State , funcindex: c.int , n: c.int) -> cstring ---
	setuservalue :: proc (L: ^State , idx: c.int ) ---
	status :: proc (L: ^State ) -> c.int ---
	stringtonumber :: proc (L: ^State , s: cstring) -> c.ptrdiff_t ---
	toboolean :: proc (L: ^State , idx: c.int ) -> c.int ---
	tocfunction :: proc (L: ^State , idx: c.int ) -> CFunction ---
	tointegerx :: proc (L: ^State , idx: c.int , isnum: ^c.int) -> Integer ---
	tolstring :: proc (L: ^State , idx: c.int , len: ^c.ptrdiff_t) -> cstring ---
	tonumberx :: proc (L: ^State , idx: c.int , isnum: ^c.int) -> Number ---
	topointer :: proc (L: ^State , idx: c.int ) -> rawptr ---
	tothread :: proc (L: ^State , idx: c.int ) -> ^State ---
	touserdata :: proc (L: ^State , idx: c.int ) -> rawptr ---
	typename :: proc (L: ^State , tp: c.int ) -> cstring ---
	upvalueid :: proc (L: ^State , fidx: c.int, n: c.int) -> rawptr ---
	upvaluejoin :: proc (L: ^State , fidx1: c.int, n1: c.int, fidx2: c.int, n2: c.int) ---
	version :: proc (L: ^State ) -> ^Number ---
	xmove :: proc (from: ^State, to: ^State, n:c.int) ---
	yieldk :: proc (L: ^State , nresults: c.int, ctx: KContext, k: KFunction ) -> c.int ---

	// Odinify
	@(link_name = "lua_pushstring")
	pushcstring :: proc (L: ^State , s: cstring) -> cstring ---

	when !JIT_ENABLED {
		getglobal :: proc (L: ^State , name: cstring) -> c.int ---
		setglobal :: proc (L: ^State , name: cstring) ---
	}
	

	type :: proc (L: ^State , idx: c.int ) -> c.int ---
}


/*
	MACROS
*/

// lua_getextraspace :: proc (L: ^State )
// {
// 	(cast(rawptr)(cast(^i8)c.ptrdiff_t(L) - LUA_EXTRASPACE));
// }	

newuserdata :: proc "c" (L: ^State, sz: c.ptrdiff_t) -> rawptr {
	return newuserdatauv(L, sz, 1)
}

tonumber :: proc "c" (L: ^State, i: c.int) -> Number
{
	return Number( tonumberx(L,(i),nil) )
}	

tointeger :: proc "c" (L: ^State ,i: c.int) -> Integer
{
	return Integer( tointegerx(L,(i),nil) )
}
pop :: proc "c" (L: ^State ,n: c.int )
{
	settop(L, -(n)-1)
}		

newtable :: proc "c" (L: ^State)
{		
	createtable(L, 0, 0)
}

register :: proc "c" (L: ^State, n: cstring, f: CFunction )
{
	pushcfunction(L, (f))
	setglobal(L, (n))
}

pushcfunction :: proc "c" (L: ^State, f: CFunction )
{
	pushcclosure(L, (f), 0)
}	

isfunction :: proc "c" (L: ^State, n: c.int) -> c.bool 
{
	return (type(L, (n)) == TFUNCTION)
}	

istable :: proc "c" (L: ^State, n:c.int) -> c.bool
{
	return (type(L, (n)) == TTABLE)
}

islightuserdata :: proc "c" (L: ^State, n:c.int) -> c.bool
{	
	return (type(L, (n)) == TLIGHTUSERDATA)
}
isnil :: proc "c" (L: ^State, n:c.int ) -> c.bool
{
	return (type(L, (n)) == TNIL)
}

isboolean :: proc "c" (L: ^State, n: c.int ) -> c.bool
{
	return (type(L, (n)) == TBOOLEAN)
}	

isthread :: proc "c" (L: ^State, n: c.int) -> c.bool
{
	return (type(L, (n)) == TTHREAD)
}

isnone :: proc "c" (L: ^State, n: c.int) -> c.bool
{
	return (type(L, (n)) == TNONE)
}
	
isnoneornil :: proc "c" (L: ^State, n:c.int) -> c.bool
{
	return (type(L, (n)) <= 0)
}

pushliteral :: proc "c" (L: ^State, s:cstring)	
{
	pushcstring(L, s)
}

pushglobaltable :: proc "c" (L: ^State)
{
	rawgeti(L, REGISTRYINDEX, RIDX_GLOBALS)
} 
	
tostring :: proc "c" (L: ^State, i: c.int) -> string
{
	return string( tolstring(L, (i), nil) )
}	

insert :: proc "c" (L: ^State, idx:c.int)
{
	rotate(L, (idx), 1)
}	

remove :: proc "c" (L: ^State, idx: c.int)
{	
	rotate(L, (idx), -1)
	pop(L, 1)
}

replace :: proc "c" (L: ^State, idx: c.int)	
{
	copy(L, -1, (idx))
	pop(L, 1)
}

yield :: proc "c" (L : ^State, n: c.int)
{
	yieldk(L, (n), 0, nil)
}		

call :: proc "c" (L: ^State, n: c.int, r: c.int)
{
	callk(L, (n), (r), 0, nil)
}

pcall :: proc "c" (L: ^State, n: c.int, r: c.int, f: c.int) -> c.int {
	return pcallk(L, (n), (r), (f), 0, nil)
}

upvalueindex :: proc "c" (i: c.int) -> c.int {
	return (REGISTRYINDEX - (i))
}


MAX_ODIN_STRLEN :: #config(LUA_MAX_ODIN_STRLEN, 256)
@(private = "file")
_odin_string_backing: [MAX_ODIN_STRLEN]byte 

// lua_pushstring will convert a string to cstring and push.
pushstring :: proc "c" (L: ^State, str: string) {
	context = {}
	sb := strings.builder_from_bytes(_odin_string_backing[:]) // This should be contextless in core
	strings.write_string(&sb, str)
	strings.write_byte(&sb, 0) // make it null terminated
	cstr := strings.unsafe_string_to_cstring(strings.to_string(sb))
	pushcstring(L, cstr)
}

/*
	New macro implementations for LuaJIT compatibility
*/
when JIT_ENABLED {
	setglobal :: jit_setglobal
	getglobal :: jit_getglobal
}