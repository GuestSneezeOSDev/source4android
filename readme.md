# Source4android
> [!CAUTION]
> Please do not use this as its not complete yet, please proceed with caution.

Source4android is a project which allows you to port you HL2, Portal, TF2, etc mod to the android platform without using leaked code.
# Steps to implementing Source4Android
1. You will need to download [vs-android](http://www.gavpugh.com/downloads/vs-android-0.964.zip)
2. Add this to your `.vcxproj`
```xml
<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|Android'">
  <OutputPath>$(SolutionDir)bin\$(Configuration)\android\</OutputPath>
</PropertyGroup>
```
3. Make your vcxproj compile for shared library (`.so`)
4. In `cdll_client_int.cpp` include `touch.h` and in line 732 delete `public` and under it Add the following code
```cpp
virtual void IN_TouchEvent( int type, int fingerId, int x, int y );
```
In line 1044 add 	`gTouch.Init();`, Line 1422 rename `void CHLClient::ExtraMouseSample( float frametime, bool active )` to `void CHLClient::IN_TouchEvent( int type, int fingerId, int x, int y )`
and add in the function
```cpp
if( enginevgui->IsGameUIVisible() )
		return;
	touch_event_t ev;
	ev.type = type;
	ev.fingerid = fingerId;
	ev.x = x;
	ev.y = y;
	gTouch.ProcessEvent( &ev );
}
```
5. In in_main.cpp, include `touch.h`,`ienginevgui.h`, and `inputsystem/iinputsystem.h` and in line 959 add
```cpp
gTouch.Move( frametime, cmd );
```
in line 1205, change 
```cpp
if ( in_joystick.GetInt() || g_pSixenseInput->IsEnabled() )
```
to
```cpp
	if ( in_joystick.GetInt() || g_pSixenseInput->IsEnabled() || touch_enable.GetInt() )
```
and line 1207 change
```cpp
	if ( in_joystick.GetInt() )
```
to
```cpp
	if ( in_joystick.GetInt() || touch_enable.GetInt() )
```

> [!IMPORTANT]
> In InputEnums.h add the following under line 80

```cpp
	IE_FingerDown, // Touch Support
	IE_FingerUp, // Touch Support
	IE_FingerMotion, // Touch Support
```

6. here are the touch.h files.
touch.h:
```c
#include "utllinkedlist.h"
#include "vgui/ISurface.h"
#include "vgui/VGUI.h"
#include <vgui_controls/Panel.h>
#include "cbase.h"
#include "kbutton.h"
#include "usercmd.h"

extern ConVar touch_enable;

#define GRID_COUNT touch_grid_count.GetInt()
#define GRID_COUNT_X (GRID_COUNT)
#define GRID_COUNT_Y (GRID_COUNT * screen_h / screen_w)
#define GRID_X (1.0f/GRID_COUNT_X)
#define GRID_Y (screen_w/screen_h/GRID_COUNT_X)
#define GRID_ROUND_X(x) ((float)round( x * GRID_COUNT_X ) / GRID_COUNT_X)
#define GRID_ROUND_Y(x) ((float)round( x * GRID_COUNT_Y ) / GRID_COUNT_Y)

#define CMD_SIZE 64

#define TOUCH_FL_HIDE                   (1U << 0)
#define TOUCH_FL_NOEDIT                 (1U << 1)
#define TOUCH_FL_CLIENT                 (1U << 2)
#define TOUCH_FL_MP                             (1U << 3)
#define TOUCH_FL_SP                             (1U << 4)
#define TOUCH_FL_DEF_SHOW               (1U << 5)
#define TOUCH_FL_DEF_HIDE               (1U << 6)
#define TOUCH_FL_DRAW_ADDITIVE  (1U << 7)
#define TOUCH_FL_STROKE                 (1U << 8)
#define TOUCH_FL_PRECISION              (1U << 9)

enum ETouchButtonType
{
	touch_command = 0, // Tap button
	touch_move,    // Like a joystick stick.
	touch_joy,     // Like a joystick stick, centered.
	touch_dpad,    // Only two directions.
	touch_look,     // Like a touchpad.
	touch_key
};

enum ETouchState
{
	state_none = 0,
	state_edit,
	state_edit_move
};

enum ETouchRound
{
	round_none = 0,
	round_grid,
	round_aspect
};

struct rgba_t
{
	rgba_t(unsigned char r, unsigned char g, unsigned char b, unsigned char a = 255) : r(r), g(g), b(b), a(a) { }
	rgba_t() : r(0), g(0), b(0), a(0) { }
	rgba_t(unsigned char* x) : r(x[0]), g(x[1]), b(x[2]), a(x[3]) { }

	operator unsigned char* () { return &r; }

	unsigned char r, g, b, a;
};

struct event_clientcmd_t
{
	char buf[CMD_SIZE];
};

struct event_s
{
	int type;
	float x, y, dx, dy;
	int fingerid;
} typedef touch_event_t;


struct CTouchTexture
{
	IVTFTexture* vtf;

	float X0, Y0, X1, Y1; // position in atlas texture
	int height, width;
	int textureID;
	bool isInAtlas;
	char szName[1024];
};

class CTouchButton
{
public:
	// Touch button type: tap, stick or slider
	ETouchButtonType type;

	// Field of button in pixels
	float x1, y1, x2, y2;

	rgba_t color;
	char texturefile[256];
	char command[256];
	char name[32];
	int finger;
	int flags;
	float fade;
	float fadespeed;
	float fadeend;
	float aspect;
	CTouchTexture* texture;
};

class CTouchPanel : public vgui::Panel
{
	DECLARE_CLASS_SIMPLE(CTouchPanel, vgui::Panel);

public:
	CTouchPanel(vgui::VPANEL parent);
	virtual			~CTouchPanel(void) {};
	virtual void	Paint();
	virtual void    ApplySchemeSettings(vgui::IScheme* pScheme);

protected:
	MESSAGE_FUNC_INT_INT(OnScreenSizeChanged, "OnScreenSizeChanged", oldwide, oldtall);
};

abstract_class ITouchPanel
{
public:
	virtual void		Create(vgui::VPANEL parent) = 0;
	virtual void		Destroy(void) = 0;
};

class VTouchPanel : public ITouchPanel
{
private:
	CTouchPanel* touchPanel;
public:
	VTouchPanel(void)
	{
		touchPanel = NULL;
	}

	void Create(vgui::VPANEL parent)
	{
		touchPanel = new CTouchPanel(parent);
	}

	void Destroy(void)
	{
		if (touchPanel)
		{
			touchPanel->SetParent((vgui::Panel*)NULL);
			touchPanel->MarkForDeletion();
			touchPanel = NULL;
		}
	}
};

class CTouchControls
{
public:
	void Init();
	void LevelInit();
	void Shutdown();

	void Paint();
	void Frame();

	void AddButton(const char* name, const char* texturefile, const char* command, float x1, float y1, float x2, float y2, rgba_t color = rgba_t(255, 255, 255, 255), int round = 2, float aspect = 1.f, int flags = 0);
	void RemoveButton(const char* name);
	void ResetToDefaults();
	void HideButton(const char* name);
	void ShowButton(const char* name);
	void ListButtons();
	void RemoveButtons();

	CTouchButton* FindButton(const char* name);
	//	bool FindNextButton( const char *name, CTouchButton &button );
	void SetTexture(const char* name, const char* file);
	void SetColor(const char* name, rgba_t color);
	void SetCommand(const char* name, const char* cmd);
	void SetFlags(const char* name, int flags);
	void WriteConfig();

	void IN_CheckCoords(float* x1, float* y1, float* x2, float* y2);
	void InitGrid();

	void Move(float frametime, CUserCmd* cmd);
	void IN_Look();

	void ProcessEvent(touch_event_t* ev);
	void FingerPress(touch_event_t* ev);
	void FingerMotion(touch_event_t* ev);
	void GetTouchAccumulators(float* forward, float* side, float* yaw, float* pitch);
	void GetTouchDelta(float yaw, float pitch, float* dx, float* dy);
	void EditEvent(touch_event_t* ev);
	void EnableTouchEdit(bool enable);
	void CreateAtlasTexture();

	CTouchPanel* touchPanel;
	float screen_h, screen_w;
	float forward, side, movecount;
	float yaw, pitch;
	rgba_t gridcolor;

private:
	bool initialized = false;
	ETouchState state;
	CUtlLinkedList<CTouchButton*> btns;
	CUtlVector<CTouchTexture*> textureList;

	int look_finger, move_finger, wheel_finger;
	CTouchButton* move_button;

	float move_start_x, move_start_y;
	float m_flPreviousYaw, m_flPreviousPitch;

	int touchTextureID;
	IMesh* m_pMesh;
	CMeshBuilder meshBuilder;

	// editing
	CTouchButton* edit;
	CTouchButton* selection;
	int resize_finger;
	bool showbuttons;
	bool clientonly;
	rgba_t scolor;
	int swidth;
	bool precision;
	// textures
	int showtexture;
	int hidetexture;
	int resettexture;
	int closetexture;
	int joytexture; // touch indicator
	bool configchanged;
	bool config_loaded;
	vgui::HFont textfont;
	int mouse_events;

	bool m_bCutScene;
	float m_flHideTouch;
	int m_AlphaDiff;
};

extern CTouchControls gTouch;
extern VTouchPanel* touch_panel;
```
and here is the touch.cpp
```cpp
#include "cbase.h"
#include "convar.h"
#include <string.h>
#include "vgui/IInputInternal.h"
#include "VGuiMatSurface/IMatSystemSurface.h"
#include "vgui/ISurface.h"
#include "touch.h"
#include "cdll_int.h"
#include "ienginevgui.h"
#include "in_buttons.h"
#include "filesystem.h"
#include "tier0/icommandline.h"
#include "vgui_controls/Button.h"
#include "viewrender.h"

#define STB_RECT_PACK_IMPLEMENTATION
#include "stb_rect_pack.h"
#include <isaverestore.h>

extern ConVar cl_sidespeed;
extern ConVar cl_forwardspeed;
extern ConVar cl_upspeed;
extern ConVar default_fov;

extern IMatSystemSurface* g_pMatSystemSurface;

#ifdef ANDROID
#define TOUCH_DEFAULT "1"
#else
#define TOUCH_DEFAULT "0"
#endif

extern ConVar sensitivity;

#define TOUCH_DEFAULT_CFG "touch_default.cfg"
#define MIN_ALPHA_IN_CUTSCENE 20

ConVar touch_enable("touch_enable", TOUCH_DEFAULT, FCVAR_ARCHIVE);
ConVar touch_draw("touch_draw", "1", FCVAR_ARCHIVE);
ConVar touch_filter("touch_filter", "0", FCVAR_ARCHIVE);
ConVar touch_forwardzone("touch_forwardzone", "0.06", FCVAR_ARCHIVE, "forward touch zone");
ConVar touch_sidezone("touch_sidezone", "0.06", FCVAR_ARCHIVE, "side touch zone");
ConVar touch_pitch("touch_pitch", "90", FCVAR_ARCHIVE, "touch pitch sensitivity");
ConVar touch_yaw("touch_yaw", "120", FCVAR_ARCHIVE, "touch yaw sensitivity");
ConVar touch_config_file("touch_config_file", "touch.cfg", FCVAR_ARCHIVE, "current touch profile file");
ConVar touch_grid_count("touch_grid_count", "50", FCVAR_ARCHIVE, "touch grid count");
ConVar touch_grid_enable("touch_grid_enable", "1", FCVAR_ARCHIVE, "enable touch grid");
ConVar touch_precise_amount("touch_precise_amount", "0.5", FCVAR_ARCHIVE, "sensitivity multiplier for precise-look");

ConVar touch_button_info("touch_button_info", "0", FCVAR_ARCHIVE);

#define boundmax( num, high ) ( (num) < (high) ? (num) : (high) )
#define boundmin( num, low )  ( (num) >= (low) ? (num) : (low)  )
#define bound( low, num, high ) ( boundmin( boundmax(num, high), low ))
#define S

extern IVEngineClient* engine;

CTouchControls gTouch;
static VTouchPanel g_TouchPanel;
VTouchPanel* touch_panel = &g_TouchPanel;

CTouchPanel::CTouchPanel(vgui::VPANEL parent) : BaseClass(NULL, "TouchPanel")
{
	SetParent(parent);

	int w, h;
	engine->GetScreenSize(w, h);
	SetBounds(0, 0, w, h);

	SetFgColor(Color(0, 0, 0, 255));
	SetPaintBackgroundEnabled(false);

	SetKeyBoardInputEnabled(false);
	SetMouseInputEnabled(false);

	SetVisible(true);
}

void CTouchPanel::Paint()
{
	gTouch.Frame();
}

void CTouchPanel::OnScreenSizeChanged(int iOldWide, int iOldTall)
{
	BaseClass::OnScreenSizeChanged(iOldWide, iOldTall);

	int w, h;
	w = ScreenWidth();
	h = ScreenHeight();
	gTouch.screen_w = ScreenWidth(); gTouch.screen_h = h;

	SetBounds(0, 0, w, h);
}

void CTouchPanel::ApplySchemeSettings(vgui::IScheme* pScheme)
{
	BaseClass::ApplySchemeSettings(pScheme);

	int w, h;
	w = ScreenWidth();
	h = ScreenHeight();
	gTouch.screen_w = ScreenWidth(); gTouch.screen_h = h;

	SetBounds(0, 0, w, h);
}

CON_COMMAND(touch_addbutton, "add native touch button")
{
	rgba_t color;
	int argc = args.ArgC();

	if (argc >= 12)
	{
		float aspect = 1.f;
		int flags = 0;

		if (argc >= 13)
			flags = Q_atoi(args[12]);
		if (argc >= 14)
			aspect = Q_atof(args[13]);

		color = rgba_t(Q_atoi(args[8]), Q_atoi(args[9]), Q_atoi(args[10]), Q_atoi(args[11]));
		gTouch.AddButton(args[1], args[2], args[3],
			Q_atof(args[4]), Q_atof(args[5]),
			Q_atof(args[6]), Q_atof(args[7]),
			color, round_aspect, aspect, flags);

		return;
	}

	if (argc >= 8)
	{
		color = rgba_t(255, 255, 255);

		gTouch.AddButton(args[1], args[2], args[3],
			Q_atof(args[4]), Q_atof(args[5]),
			Q_atof(args[6]), Q_atof(args[7]),
			color);
		return;
	}
	if (argc >= 4)
	{
		color = rgba_t(255, 255, 255);
		gTouch.AddButton(args[1], args[2], args[3], 0.4, 0.4, 0.6, 0.6);
		return;
	}

	Msg("Usage: touch_addbutton <name> <texture> <command> [<x1> <y1> <x2> <y2> [ r g b a ] ]\n");
}

CON_COMMAND(touch_removebutton, "remove native touch button")
{
	if (args.ArgC() > 1)
		gTouch.RemoveButton(args[1]);
	else
		Msg("Usage: touch_removebutton <name>\n");
}

#if 0
CON_COMMAND(touch_settexture, "set button texture")
{
	if (args.ArgC() >= 3)
	{
		gTouch.SetTexture(args[1], args[2]);
		return;
	}
	Msg("Usage: touch_settexture <name> <file>\n");
}
#endif

CON_COMMAND(touch_enableedit, "enable button editing mode")
{
	gTouch.EnableTouchEdit(true);
}

CON_COMMAND(touch_disableedit, "disable button editing mode")
{
	gTouch.EnableTouchEdit(false);
}

CON_COMMAND(touch_setcolor, "change button color")
{
	if (args.ArgC() >= 6)
	{
		rgba_t color(Q_atoi(args[2]), Q_atoi(args[3]), Q_atoi(args[4]), Q_atoi(args[5]));
		gTouch.SetColor(args[1], color);
	}
	else
		Msg("Usage: touch_setcolor <name> <r> <g> <b> <a>\n");
}

CON_COMMAND(touch_setcommand, "change button command")
{
	if (args.ArgC() >= 3)
		gTouch.SetCommand(args[1], args[2]);
	else
		Msg("Usage: touch_setcommand <name> <command>\n");
}

CON_COMMAND(touch_setflags, "change button flags")
{
	if (args.ArgC() >= 3)
		gTouch.SetFlags(args[1], Q_atoi(args[2]));
	else
		Msg("Usage: touch_setflags <name> <flags>\n");
}

CON_COMMAND(touch_show, "show button")
{
	if (args.ArgC() >= 2)
		gTouch.ShowButton(args[1]);
	else
		Msg("Usage: touch_show <name>\n");
}

CON_COMMAND(touch_hide, "hide button")
{
	if (args.ArgC() >= 2)
		gTouch.HideButton(args[1]);
	else
		Msg("Usage: touch_hide <name>\n");
}

CON_COMMAND(touch_list, "list buttons")
{
	gTouch.ListButtons();
}

CON_COMMAND(touch_removeall, "remove all buttons")
{
	gTouch.RemoveButtons();
}

CON_COMMAND(touch_writeconfig, "save current config")
{
	gTouch.WriteConfig();
}


CON_COMMAND(touch_loaddefaults, "generate config from defaults")
{
	gTouch.ResetToDefaults();
}

CON_COMMAND(touch_setgridcolor, "change grid color")
{
	if (args.ArgC() >= 5)
		gTouch.gridcolor = rgba_t(Q_atoi(args[1]), Q_atoi(args[2]), Q_atoi(args[3]), Q_atoi(args[4]));
	else
		Msg("Usage: touch_setgridcolor <r> <g> <b> <a>\n");
}

/*
CON_COMMAND( touch_roundall, "round all buttons coordinates to grid" )
{

}

CON_COMMAND( touch_exportconfig, "export config keeping aspect ratio" )
{

}

CON_COMMAND( touch_reloadconfig, "load config, not saving changes" )
{

}
*/

/*
CON_COMMAND( touch_fade, "start fade animation for selected buttons" )
{

}

CON_COMMAND( touch_toggleselection, "toggle visibility on selected button in editor" )
{

}*/

void CTouchControls::GetTouchAccumulators(float* side, float* forward, float* yaw, float* pitch)
{
	*forward = this->forward;
	*side = this->side;
	*pitch = this->pitch;
	*yaw = this->yaw;
	this->yaw = 0.f;
	this->pitch = 0.f;
}

void CTouchControls::GetTouchDelta(float yaw, float pitch, float* dx, float* dy)
{
	// Apply filtering?
	if (touch_filter.GetBool())
	{
		// Average over last two samples
		*dx = (yaw + m_flPreviousYaw) * 0.5f;
		*dy = (pitch + m_flPreviousPitch) * 0.5f;
	}
	else
	{
		*dx = yaw;
		*dy = pitch;
	}

	// Latch previous
	m_flPreviousYaw = yaw;
	m_flPreviousPitch = pitch;
}

void CTouchControls::ResetToDefaults()
{
	rgba_t color(255, 255, 255, 155);
	char buf[MAX_PATH];
	gridcolor = rgba_t(255, 0, 0, 30);

	RemoveButtons();

	Q_snprintf(buf, sizeof buf, "cfg/%s", TOUCH_DEFAULT_CFG);
	if (!filesystem->FileExists(buf))
	{
		AddButton("look", "", "_look", 0.5, 0, 1, 1, color, 0, 0, 0);
		AddButton("move", "", "_move", 0, 0, 0.5, 1, color, 0, 0, 0);

		AddButton("use", "vgui/touch/use", "+use", 0.880000, 0.213333, 1.000000, 0.426667, color);
		AddButton("jump", "vgui/touch/jump", "+jump", 0.880000, 0.462222, 1.000000, 0.675556, color);
		AddButton("attack", "vgui/touch/shoot", "+attack", 0.760000, 0.583333, 0.880000, 0.796667, color);
		AddButton("attack2", "vgui/touch/shoot_alt", "+attack2", 0.760000, 0.320000, 0.880000, 0.533333, color);
		AddButton("duck", "vgui/touch/crouch", "+duck", 0.880000, 0.746667, 1.000000, 0.960000, color);
		AddButton("tduck", "vgui/touch/tduck", ";+duck", 0.560000, 0.817778, 0.620000, 0.924444, color);
		AddButton("zoom", "vgui/touch/zoom", "+zoom", 0.680000, 0.00000, 0.760000, 0.142222, color);
		AddButton("speed", "vgui/touch/speed", "+speed", 0.180000, 0.568889, 0.280000, 0.746667, color);
		AddButton("loadquick", "vgui/touch/load", "load quick", 0.760000, 0.000000, 0.840000, 0.142222, color);
		AddButton("savequick", "vgui/touch/save", "save quick", 0.840000, 0.000000, 0.920000, 0.142222, color);
		AddButton("reload", "vgui/touch/reload", "+reload", 0.000000, 0.320000, 0.120000, 0.533333, color);
		AddButton("flashlight", "vgui/touch/flash_light_filled", "impulse 100", 0.920000, 0.000000, 1.000000, 0.142222, color);
		AddButton("invnext", "vgui/touch/next_weap", "invnext", 0.000000, 0.533333, 0.120000, 0.746667, color);
		AddButton("invprev", "vgui/touch/prev_weap", "invprev", 0.000000, 0.071111, 0.120000, 0.284444, color);
		AddButton("edit", "vgui/touch/settings", "touch_enableedit", 0.420000, 0.000000, 0.500000, 0.151486, color);
		AddButton("menu", "vgui/touch/menu", "gameui_activate", 0.000000, 0.00000, 0.080000, 0.142222, color);
	}
	else
	{
		Q_snprintf(buf, sizeof buf, "exec %s", TOUCH_DEFAULT_CFG);
		engine->ExecuteClientCmd(buf);
	}

	WriteConfig();
}

void CTouchControls::Init()
{
	int w, h;
	engine->GetScreenSize(w, h);
	screen_w = w; screen_h = h;

	touchTextureID = 0;
	configchanged = false;
	config_loaded = false;
	btns.EnsureCapacity(64);
	look_finger = move_finger = resize_finger = -1;
	forward = side = 0.f;
	pitch = yaw = 0.f;
	scolor = rgba_t(1, 1, 1, 1);
	state = state_none;
	swidth = 1;
	move_button = edit = selection = NULL;
	showbuttons = true;
	clientonly = false;
	precision = false;
	mouse_events = 0;
	move_start_x = move_start_y = 0.0f;
	m_flPreviousYaw = m_flPreviousPitch = 0.f;
	gridcolor = rgba_t(255, 0, 0, 30);

	m_bCutScene = false;
	showtexture = hidetexture = resettexture = closetexture = joytexture = 0;
	configchanged = false;

	rgba_t color(255, 255, 255, 155);

	AddButton("look", "", "_look", 0.5, 0, 1, 1, color, 0, 0, 0);
	AddButton("move", "", "_move", 0, 0, 0.5, 1, color, 0, 0, 0);

	AddButton("use", "vgui/touch/use", "+use", 0.880000, 0.213333, 1.000000, 0.426667, color);
	AddButton("jump", "vgui/touch/jump", "+jump", 0.880000, 0.462222, 1.000000, 0.675556, color);
	AddButton("attack", "vgui/touch/shoot", "+attack", 0.760000, 0.583333, 0.880000, 0.796667, color);
	AddButton("attack2", "vgui/touch/shoot_alt", "+attack2", 0.760000, 0.320000, 0.880000, 0.533333, color);
	AddButton("duck", "vgui/touch/crouch", "+duck", 0.880000, 0.746667, 1.000000, 0.960000, color);
	AddButton("tduck", "vgui/touch/tduck", ";+duck", 0.560000, 0.817778, 0.620000, 0.924444, color);
	AddButton("zoom", "vgui/touch/zoom", "+zoom", 0.680000, 0.00000, 0.760000, 0.142222, color);
	AddButton("speed", "vgui/touch/speed", "+speed", 0.180000, 0.568889, 0.280000, 0.746667, color);
	AddButton("loadquick", "vgui/touch/load", "load quick", 0.760000, 0.000000, 0.840000, 0.142222, color);
	AddButton("savequick", "vgui/touch/save", "save quick", 0.840000, 0.000000, 0.920000, 0.142222, color);
	AddButton("reload", "vgui/touch/reload", "+reload", 0.000000, 0.320000, 0.120000, 0.533333, color);
	AddButton("flashlight", "vgui/touch/flash_light_filled", "impulse 100", 0.920000, 0.000000, 1.000000, 0.142222, color);
	AddButton("invnext", "vgui/touch/next_weap", "invnext", 0.000000, 0.533333, 0.120000, 0.746667, color);
	AddButton("invprev", "vgui/touch/prev_weap", "invprev", 0.000000, 0.071111, 0.120000, 0.284444, color);
	AddButton("edit", "vgui/touch/settings", "touch_enableedit", 0.420000, 0.000000, 0.500000, 0.151486, color);
	AddButton("menu", "vgui/touch/menu", "gameui_activate", 0.000000, 0.00000, 0.080000, 0.142222, color);

	char buf[256];

	Q_snprintf(buf, sizeof buf, "cfg/%s", touch_config_file.GetString());
	if (filesystem->FileExists(buf, "MOD"))
	{
		Q_snprintf(buf, sizeof buf, "exec %s\n", touch_config_file.GetString());
		engine->ExecuteClientCmd(buf);
	}
	else
		ResetToDefaults();

	CTouchTexture* texture = new CTouchTexture;
	texture->isInAtlas = false;
	texture->textureID = 0;
	texture->X0 = 0; texture->X1 = 0; texture->Y0 = 0; texture->Y1 = 0;

	Q_strncpy(texture->szName, "vgui/touch/back", sizeof(texture->szName));
	textureList.AddToTail(texture);

	CreateAtlasTexture();
	m_flHideTouch = 0.f;

	initialized = true;
}

void CTouchControls::LevelInit()
{
	m_bCutScene = false;
	m_AlphaDiff = 0;
	m_flHideTouch = 0;
}

int nextPowerOfTwo(int x)
{
	if ((x & (x - 1)) == 0)
		return x;

	int t = 1 << 30;
	while (x < t) t >>= 1;

	return t << 1;
}

void CTouchControls::CreateAtlasTexture()
{
	char fullFileName[MAX_PATH];

	int atlasSize = 0;

	stbrp_rect* rects = (stbrp_rect*)malloc(textureList.Count() * sizeof(stbrp_rect));
	memset(rects, 0, sizeof(stbrp_node) * textureList.Count());

	if (touchTextureID)
		vgui::surface()->DeleteTextureByID(touchTextureID);

	int rectCount = 0;

	for (int i = 0; i < textureList.Count(); i++)
	{
		CTouchTexture* t = textureList[i];
		Q_snprintf(fullFileName, MAX_PATH, "materials/%s.vtf", t->szName);

		FileHandle_t fp;
		fp = ::filesystem->Open(fullFileName, "rb");
		if (!fp)
		{
			t->textureID = vgui::surface()->CreateNewTextureID();
			vgui::surface()->DrawSetTextureFile(t->textureID, t->szName, true, false);
			continue;
		}

		::filesystem->Seek(fp, 0, FILESYSTEM_SEEK_TAIL);
		int srcVTFLength = ::filesystem->Tell(fp);
		::filesystem->Seek(fp, 0, FILESYSTEM_SEEK_HEAD);

		CUtlBuffer buf;
		buf.EnsureCapacity(srcVTFLength);
		int bytesRead = ::filesystem->Read(buf.Base(), srcVTFLength, fp);
		::filesystem->Close(fp);

		buf.SeekGet(CUtlBuffer::SEEK_HEAD, 0); // Need to set these explicitly since ->Read goes straight to memory and skips them.
		buf.SeekPut(CUtlBuffer::SEEK_HEAD, bytesRead);

		t->vtf = CreateVTFTexture();
		if (t->vtf->Unserialize(buf))
		{
			if (t->vtf->Format() != IMAGE_FORMAT_RGBA8888 && t->vtf->Format() != IMAGE_FORMAT_BGRA8888)
			{
				t->textureID = vgui::surface()->CreateNewTextureID();
				vgui::surface()->DrawSetTextureFile(t->textureID, t->szName, true, false);
				DestroyVTFTexture(t->vtf);
				continue;
			}
			if (t->vtf->Height() != t->vtf->Width() || (t->vtf->Height() & (t->vtf->Height() - 1)) != 0)
				Error("%s texture is wrong! Don't use npot textures for touch.");

			t->height = t->vtf->Height();
			t->width = t->vtf->Width();
			t->isInAtlas = true;

			atlasSize += t->width * t->height;
		}
		else
		{
			DestroyVTFTexture(t->vtf);
			t->textureID = vgui::surface()->CreateNewTextureID();
			vgui::surface()->DrawSetTextureFile(t->textureID, t->szName, true, false);
			continue;
		}

		rects[rectCount].h = t->height;
		rects[rectCount].w = t->width;
		rectCount++;
	}

	if (!textureList.Count() || rectCount == 0)
	{
		free(rects);
		return;
	}

	int atlasHeight = nextPowerOfTwo(sqrt((double)atlasSize));
	int sizeInBytes = atlasHeight * atlasHeight * 4;
	unsigned char* dest = new unsigned char[sizeInBytes];
	memset(dest, 0, sizeInBytes);

	int nodesCount = atlasHeight * 2;
	stbrp_node* nodes = (stbrp_node*)malloc(nodesCount * sizeof(stbrp_node));
	memset(nodes, 0, sizeof(stbrp_node) * nodesCount);

	stbrp_context context;
	stbrp_init_target(&context, atlasHeight, atlasHeight, nodes, nodesCount);
	stbrp_pack_rects(&context, rects, rectCount);

	rectCount = 0;
	for (int i = 0; i < textureList.Count(); i++)
	{
		CTouchTexture* t = textureList[i];
		if (t->textureID)
			continue;

		t->X0 = rects[rectCount].x / (float)atlasHeight;
		t->Y0 = rects[rectCount].y / (float)atlasHeight;
		t->X1 = t->X0 + t->width / (float)atlasHeight;
		t->Y1 = t->Y0 + t->height / (float)atlasHeight;

		unsigned char* src = t->vtf->ImageData(0, 0, 0);
		for (int row = 0; row < t->height; row++)
		{
			unsigned char* row_dest = dest + (row + rects[rectCount].y) * atlasHeight * 4 + rects[rectCount].x * 4;
			unsigned char* row_src = src + row * t->height * 4;

			memcpy(row_dest, row_src, t->height * 4);
		}
		rectCount++;

		DestroyVTFTexture(t->vtf);
	}

	touchTextureID = vgui::surface()->CreateNewTextureID(true);
	vgui::surface()->DrawSetTextureRGBA(touchTextureID, dest, atlasHeight, atlasHeight, 1, true);

	free(nodes);
	free(rects);
	delete[] dest;
}

void CTouchControls::Shutdown()
{
	textureList.PurgeAndDeleteElements();
	btns.PurgeAndDeleteElements();
}

void CTouchControls::RemoveButtons()
{
	btns.PurgeAndDeleteElements();
}

void CTouchControls::ListButtons()
{
	CUtlLinkedList<CTouchButton*>::iterator it;
	for (it = btns.begin(); it != btns.end(); it++)
	{
		CTouchButton* b = *it;

		Msg("%s %s %s %f %f %f %f %d %d %d %d %d\n",
			b->name, b->texturefile, b->command,
			b->x1, b->y1, b->x2, b->y2,
			b->color.r, b->color.g, b->color.b, b->color.a, b->flags);
	}
}

void CTouchControls::IN_CheckCoords(float* x1, float* y1, float* x2, float* y2)
{
	/// TODO: grid check here
	if (*x2 - *x1 < GRID_X * 2)
		*x2 = *x1 + GRID_X * 2;
	if (*y2 - *y1 < GRID_Y * 2)
		*y2 = *y1 + GRID_Y * 2;
	if (*x1 < 0)
		*x2 -= *x1, * x1 = 0;
	if (*y1 < 0)
		*y2 -= *y1, * y1 = 0;
	if (*y2 > 1)
		*y1 -= *y2 - 1, * y2 = 1;
	if (*x2 > 1)
		*x1 -= *x2 - 1, * x2 = 1;

	if (touch_grid_enable.GetBool())
	{
		*x1 = GRID_ROUND_X(*x1);
		*x2 = GRID_ROUND_X(*x2);
		*y1 = GRID_ROUND_Y(*y1);
		*y2 = GRID_ROUND_Y(*y2);
	}
}

void CTouchControls::Move(float /*frametime*/, CUserCmd* cmd)
{
}

void CTouchControls::IN_Look()
{
}

void CTouchControls::Frame()
{
	if (!initialized)
		return;

	C_BasePlayer* pPlayer = C_BasePlayer::GetLocalPlayer();

	if (pPlayer && (pPlayer->GetFlags() & FL_FROZEN || g_pIntroData != NULL))
	{
		if (!m_bCutScene)
		{
			m_bCutScene = true;
			m_AlphaDiff = 0;
		}
	}
	else if (!pPlayer)
	{
		m_bCutScene = false;
		m_AlphaDiff = 0;
		m_flHideTouch = 0;
	}
	else
		m_bCutScene = false;

	if (touch_enable.GetBool() && touch_draw.GetBool() && !enginevgui->IsGameUIVisible()) Paint();
}

void CTouchControls::Paint()
{
	if (!initialized)
		return;

	CUtlLinkedList<CTouchButton*>::iterator it;

	const rgba_t buttonEditClr = rgba_t(61, 153, 0, 40);

	if (state == state_edit)
	{
		vgui::surface()->DrawSetColor(gridcolor.r, gridcolor.g, gridcolor.b, gridcolor.a * 3); // 255, 0, 0, 200 <- default here
		float x, y;

		for (x = 0.0f; x < 1.0f; x += GRID_X)
			vgui::surface()->DrawLine(screen_w * x, 0, screen_w * x, screen_h);

		for (y = 0.0f; y < 1.0f; y += GRID_Y)
			vgui::surface()->DrawLine(0, screen_h * y, screen_w, screen_h * y);

		for (it = btns.begin(); it != btns.end(); it++)
		{
			CTouchButton* btn = *it;

			if (!(btn->flags & TOUCH_FL_NOEDIT))
			{
				if (touch_button_info.GetInt())
				{
					g_pMatSystemSurface->DrawColoredText(2, btn->x1 * screen_w, btn->y1 * screen_h, 255, 255, 255, 255, "N: %s", btn->name);			// name
					g_pMatSystemSurface->DrawColoredText(2, btn->x1 * screen_w, btn->y1 * screen_h + 10, 255, 255, 255, 255, "T: %s", btn->texturefile);	// texture
					g_pMatSystemSurface->DrawColoredText(2, btn->x1 * screen_w, btn->y1 * screen_h + 20, 255, 255, 255, 255, "C: %s", btn->command);		// command
					g_pMatSystemSurface->DrawColoredText(2, btn->x1 * screen_w, btn->y1 * screen_h + 30, 255, 255, 255, 255, "F: %i", btn->flags);		// flags
					g_pMatSystemSurface->DrawColoredText(2, btn->x1 * screen_w, btn->y1 * screen_h + 40, 255, 255, 255, 255, "RGBA: %d %d %d %d", btn->color.r, btn->color.g, btn->color.b, btn->color.a);// color
				}

				vgui::surface()->DrawSetColor(buttonEditClr.r, buttonEditClr.g, buttonEditClr.b, buttonEditClr.a); // 255, 0, 0, 50 <- default here
				vgui::surface()->DrawFilledRect(btn->x1 * screen_w, btn->y1 * screen_h, btn->x2 * screen_w, btn->y2 * screen_h);
			}
		}
	}

	CMatRenderContextPtr pRenderContext(g_pMaterialSystem);
	int meshCount = 0;

	// Draw non-atlas touch textures
	for (it = btns.begin(); it != btns.end(); it++)
	{
		CTouchButton* btn = *it;

		if (btn->texture != NULL && !(btn->flags & TOUCH_FL_HIDE))
		{
			CTouchTexture* t = btn->texture;

			if (t->textureID)
			{
				m_pMesh = pRenderContext->GetDynamicMesh(true, NULL, NULL, g_pMatSystemSurface->DrawGetTextureMaterial(t->textureID));

				meshBuilder.Begin(m_pMesh, MATERIAL_QUADS, 1);

				int alpha = (btn->color.a > MIN_ALPHA_IN_CUTSCENE) ? max(MIN_ALPHA_IN_CUTSCENE, btn->color.a - m_AlphaDiff) : btn->color.a;
				rgba_t color(btn->color.r, btn->color.g, btn->color.b, alpha);

				meshBuilder.Position3f(btn->x1 * screen_w, btn->y1 * screen_h, 0);
				meshBuilder.Color4ubv(color);
				meshBuilder.TexCoord2f(0, 0, 0);
				meshBuilder.AdvanceVertexF<VTX_HAVEPOS | VTX_HAVECOLOR, 1>();

				meshBuilder.Position3f(btn->x2 * screen_w, btn->y1 * screen_h, 0);
				meshBuilder.Color4ubv(color);
				meshBuilder.TexCoord2f(0, 1, 0);
				meshBuilder.AdvanceVertexF<VTX_HAVEPOS | VTX_HAVECOLOR, 1>();

				meshBuilder.Position3f(btn->x2 * screen_w, btn->y2 * screen_h, 0);
				meshBuilder.Color4ubv(color);
				meshBuilder.TexCoord2f(0, 1, 1);
				meshBuilder.AdvanceVertexF<VTX_HAVEPOS | VTX_HAVECOLOR, 1>();

				meshBuilder.Position3f(btn->x1 * screen_w, btn->y2 * screen_h, 0);
				meshBuilder.Color4ubv(color);
				meshBuilder.TexCoord2f(0, 0, 1);
				meshBuilder.AdvanceVertexF<VTX_HAVEPOS | VTX_HAVECOLOR, 1>();

				meshBuilder.End();

				m_pMesh->Draw();
			}
			else if (!btn->texture->isInAtlas)
				CreateAtlasTexture();

			if (!t->textureID)
				meshCount++;
		}
	}

	m_pMesh = pRenderContext->GetDynamicMesh(true, NULL, NULL, g_pMatSystemSurface->DrawGetTextureMaterial(touchTextureID));
	meshBuilder.Begin(m_pMesh, MATERIAL_QUADS, meshCount);

	for (it = btns.begin(); it != btns.end(); it++)
	{
		CTouchButton* btn = *it;

		if (btn->texture != NULL && !(btn->flags & TOUCH_FL_HIDE) && !btn->texture->textureID)
		{
			CTouchTexture* t = btn->texture;

			int alpha = (btn->color.a > MIN_ALPHA_IN_CUTSCENE) ? max(MIN_ALPHA_IN_CUTSCENE, btn->color.a - m_AlphaDiff) : btn->color.a;
			rgba_t color(btn->color.r, btn->color.g, btn->color.b, alpha);

			meshBuilder.Position3f(btn->x1 * screen_w, btn->y1 * screen_h, 0);
			meshBuilder.Color4ubv(color);
			meshBuilder.TexCoord2f(0, t->X0, t->Y0);
			meshBuilder.AdvanceVertexF<VTX_HAVEPOS | VTX_HAVECOLOR, 1>();

			meshBuilder.Position3f(btn->x2 * screen_w, btn->y1 * screen_h, 0);
			meshBuilder.Color4ubv(color);
			meshBuilder.TexCoord2f(0, t->X1, t->Y0);
			meshBuilder.AdvanceVertexF<VTX_HAVEPOS | VTX_HAVECOLOR, 1>();

			meshBuilder.Position3f(btn->x2 * screen_w, btn->y2 * screen_h, 0);
			meshBuilder.Color4ubv(color);
			meshBuilder.TexCoord2f(0, t->X1, t->Y1);
			meshBuilder.AdvanceVertexF<VTX_HAVEPOS | VTX_HAVECOLOR, 1>();

			meshBuilder.Position3f(btn->x1 * screen_w, btn->y2 * screen_h, 0);
			meshBuilder.Color4ubv(color);
			meshBuilder.TexCoord2f(0, t->X0, t->Y1);
			meshBuilder.AdvanceVertexF<VTX_HAVEPOS | VTX_HAVECOLOR, 1>();
		}
	}

	meshBuilder.End();
	m_pMesh->Draw();


	if (m_flHideTouch < gpGlobals->curtime)
	{
		if (m_bCutScene && m_AlphaDiff < 255 - MIN_ALPHA_IN_CUTSCENE)
			m_AlphaDiff++;
		else if (!m_bCutScene && m_AlphaDiff > 0)
			m_AlphaDiff--;

		m_flHideTouch = gpGlobals->curtime + 0.002f;
	}
}

void CTouchControls::AddButton(const char* name, const char* texturefile, const char* command, float x1, float y1, float x2, float y2, rgba_t color, int round, float aspect, int flags)
{
	CTouchButton* btn = new CTouchButton;
	ETouchButtonType type = touch_command;

	Q_strncpy(btn->name, name, sizeof(btn->name));
	Q_strncpy(btn->texturefile, texturefile, sizeof(btn->texturefile));
	Q_strncpy(btn->command, command, sizeof(btn->command));

	if (round)
		IN_CheckCoords(&x1, &y1, &x2, &y2);

	if (round == round_aspect)
		y2 = y1 + (x2 - x1) * (((float)screen_w) / screen_h) * aspect;

	btn->x1 = x1;
	btn->y1 = y1;
	btn->x2 = x2;
	btn->y2 = y2;
	btn->flags = flags;

	//IN_CheckCoords(&btn->x1, &btn->y1, &btn->x2, &btn->y2);

	if (Q_strcmp(command, "_look") == 0)
		type = touch_look;
	else if (Q_strcmp(command, "_move") == 0)
		type = touch_move;

	btn->color = color;
	btn->type = type;
	btn->finger = -1;

	if (btn->texturefile[0] == 0)
	{
		btn->texture = NULL;
		btns.AddToTail(btn);
		return;
	}

	for (int i = 0; i < textureList.Count(); i++)
	{
		if (strcmp(textureList[i]->szName, btn->texturefile) == 0)
		{
			btn->texture = textureList[i];
			btns.AddToTail(btn);
			return;
		}
	}

	CTouchTexture* texture = new CTouchTexture;
	btn->texture = texture;
	texture->isInAtlas = false;
	texture->textureID = 0;
	texture->X0 = 0; texture->X1 = 0; texture->Y0 = 0; texture->Y1 = 0;
	Q_strncpy(texture->szName, btn->texturefile, sizeof(btn->texturefile));
	textureList.AddToTail(texture);

	btns.AddToTail(btn);
}

void CTouchControls::ShowButton(const char* name)
{
	CTouchButton* btn = FindButton(name);
	if (btn)
		btn->flags &= ~TOUCH_FL_HIDE;
}

void CTouchControls::HideButton(const char* name)
{
	CTouchButton* btn = FindButton(name);
	if (btn)
		btn->flags |= TOUCH_FL_HIDE;
}

void CTouchControls::SetTexture(const char* name, const char* file)
{
	CTouchButton* btn = FindButton(name);

	if (btn)
	{
		Q_strncpy(btn->texturefile, file, sizeof(btn->texturefile));

		//		btn->textureID = vgui::surface()->CreateNewTextureID();
		//		vgui::surface()->DrawSetTextureFile( btn->textureID, file, true, false);
	}
}

void CTouchControls::SetColor(const char* name, rgba_t color)
{
	CTouchButton* btn = FindButton(name);
	if (btn) btn->color = color;
}

void CTouchControls::SetCommand(const char* name, const char* cmd)
{
	CTouchButton* btn = FindButton(name);
	if (btn) Q_strncpy(btn->command, cmd, sizeof btn->command);
}

void CTouchControls::SetFlags(const char* name, int flags)
{
	CTouchButton* btn = FindButton(name);
	if (btn) btn->flags = flags;
}

void CTouchControls::RemoveButton(const char* name)
{
	for (int i = 0; i < btns.Count(); i++)
	{
		if (Q_strncmp(btns[i]->name, name, sizeof(btns[i]->name)) == 0)
			btns.Free(i);
	}
}

CTouchButton* CTouchControls::FindButton(const char* name)
{
	CUtlLinkedList<CTouchButton*>::iterator it;
	for (it = btns.begin(); it != btns.end(); it++)
	{
		CTouchButton* button = *it;

		if (Q_strncmp(button->name, name, sizeof(button->name)) == 0)
			return button;
	}
	return NULL;
}

void CTouchControls::ProcessEvent(touch_event_t* ev)
{
	if (!touch_enable.GetBool())
		return;

	if (state == state_edit)
	{
		EditEvent(ev);
		return;
	}

	if (ev->type == IE_FingerMotion)
		FingerMotion(ev);
	else
		FingerPress(ev);
}

void CTouchControls::EditEvent(touch_event_t* ev)
{
	const float x = ev->x;
	const float y = ev->y;

	//CUtlLinkedList<CTouchButton*>::iterator it;

	if (ev->type == IE_FingerDown)
	{
		//for( it = btns.end(); it != btns.begin(); it-- ) unexpected, doesn't work
		for (int i = btns.Count() - 1; i >= 0; i--)
		{
			CTouchButton* btn = btns[i];
			if (x > btn->x1 && x < btn->x2 && y > btn->y1 && y < btn->y2)
			{
				if (btn->flags & TOUCH_FL_HIDE)
					continue;

				if (btn->flags & TOUCH_FL_NOEDIT)
				{
					engine->ClientCmd_Unrestricted(btn->command);
					continue;
				}

				if (move_finger == -1)
				{
					move_finger = ev->fingerid;
					selection = btn;
					break;
				}
				else if (resize_finger == -1)
				{
					resize_finger = ev->fingerid;
				}
			}
		}
	}
	else if (ev->type == IE_FingerUp)
	{
		if (ev->fingerid == move_finger)
		{
			move_finger = -1;
			IN_CheckCoords(&selection->x1, &selection->y1, &selection->x2, &selection->y2);
			selection = nullptr;
		}
		else if (ev->fingerid == resize_finger)
			resize_finger = -1;
	}
	else // IE_FingerMotion
	{
		if (!selection)
			return;

		if (move_finger == ev->fingerid)
		{
			selection->x1 += ev->dx;
			selection->x2 += ev->dx;
			selection->y1 += ev->dy;
			selection->y2 += ev->dy;
		}
		else if (resize_finger == ev->fingerid)
		{
			selection->x2 += ev->dx;
			selection->y2 += ev->dy;
		}
	}
}


void CTouchControls::FingerMotion(touch_event_t* ev) // finger in my ass
{
	const float x = ev->x;
	const float y = ev->y;

	float f, s;

	CUtlLinkedList<CTouchButton*>::iterator it;
	for (it = btns.begin(); it != btns.end(); it++)
	{
		CTouchButton* btn = *it;
		if (btn->finger == ev->fingerid)
		{
			if (btn->type == touch_move)
			{
				f = (move_start_y - y) / touch_forwardzone.GetFloat();
				s = (move_start_x - x) / touch_sidezone.GetFloat();
				forward = bound(-1, f, 1);
				side = bound(-1, s, 1);
			}
			else if (btn->type == touch_look)
			{
				yaw += ev->dx;
				pitch += ev->dy;
			}
		}
	}
}

void CTouchControls::FingerPress(touch_event_t* ev)
{
	const float x = ev->x;
	const float y = ev->y;

	CUtlLinkedList<CTouchButton*>::iterator it;

	if (ev->type == IE_FingerDown)
	{
		for (it = btns.begin(); it != btns.end(); it++)
		{
			CTouchButton* btn = *it;
			if (x > btn->x1 && x < btn->x2 && y > btn->y1 && y < btn->y2)
			{
				if (btn->flags & TOUCH_FL_HIDE)
					continue;

				btn->finger = ev->fingerid;
				if (btn->type == touch_move)
				{
					if (move_finger == -1)
					{
						move_start_x = x;
						move_start_y = y;
						move_finger = ev->fingerid;
					}
					else
						btn->finger = move_finger;
				}
				else if (btn->type == touch_look)
				{
					if (look_finger == -1)
						look_finger = ev->fingerid;
					else
						btn->finger = look_finger;
				}
				else
					engine->ClientCmd_Unrestricted(btn->command);
			}
		}
	}
	else if (ev->type == IE_FingerUp)
	{
		for (it = btns.begin(); it != btns.end(); it++)
		{
			CTouchButton* btn = *it;

			if (btn->flags & TOUCH_FL_HIDE)
				continue;

			if (btn->finger == ev->fingerid)
			{
				btn->finger = -1;

				if (btn->type == touch_move)
				{
					forward = side = 0;
					move_finger = -1;
				}
				else if (btn->type == touch_look)
					look_finger = -1;
				else if (btn->command[0] == '+')
				{
					char cmd[256];

					Q_snprintf(cmd, sizeof cmd, "%s", btn->command);
					cmd[0] = '-';
					engine->ClientCmd_Unrestricted(cmd);
				}
			}
		}
	}
}

void CTouchControls::EnableTouchEdit(bool enable)
{
	if (enable)
	{
		state = state_edit;
		resize_finger = move_finger = look_finger = wheel_finger = -1;
		move_button = NULL;
		configchanged = true;
		AddButton("close_edit", "vgui/touch/back", "touch_disableedit", 0.020000, 0.800000, 0.100000, 0.977778, rgba_t(255, 255, 255, 255), 0, 1.f, TOUCH_FL_NOEDIT);
	}
	else
	{
		state = state_none;
		resize_finger = move_finger = look_finger = wheel_finger = -1;
		move_button = NULL;
		configchanged = false;
		RemoveButton("close_edit");
		WriteConfig();
	}
}

void CTouchControls::WriteConfig()
{
	FileHandle_t f;
	char newconfigfile[128];
	char oldconfigfile[128];
	char configfile[128];

#define IsEmpty Count
	if (btns.IsEmpty() == 0)
		return;

	if (CommandLine()->FindParm("-nowriteconfig"))
		return;

	DevMsg("Touch_WriteConfig(): %s\n", touch_config_file.GetString());

	Q_snprintf(newconfigfile, 64, "cfg/%s.new", touch_config_file.GetString());
	Q_snprintf(oldconfigfile, 64, "cfg/%s.bak", touch_config_file.GetString());
	Q_snprintf(configfile, 64, "cfg/%s", touch_config_file.GetString());

	f = filesystem->Open(newconfigfile, "w+");

	if (f)
	{
		filesystem->FPrintf(f, "//=======================================================================\n");
		filesystem->FPrintf(f, "//\t\t\ttouchscreen config\n");
		filesystem->FPrintf(f, "//=======================================================================\n");
		filesystem->FPrintf(f, "\ntouch_config_file \"%s\"\n", touch_config_file.GetString());
		filesystem->FPrintf(f, "\n// touch cvars\n");
		filesystem->FPrintf(f, "\n// sensitivity settings\n");
		filesystem->FPrintf(f, "touch_pitch \"%f\"\n", touch_pitch.GetFloat());
		filesystem->FPrintf(f, "touch_yaw \"%f\"\n", touch_yaw.GetFloat());
		filesystem->FPrintf(f, "touch_forwardzone \"%f\"\n", touch_forwardzone.GetFloat());
		filesystem->FPrintf(f, "touch_sidezone \"%f\"\n", touch_sidezone.GetFloat());
		/*		filesystem->FPrintf( f, "touch_nonlinear_look \"%d\"\n",touch_nonlinear_look.GetBool() );
				filesystem->FPrintf( f, "touch_pow_factor \"%f\"\n", touch_pow_factor->value );
				filesystem->FPrintf( f, "touch_pow_mult \"%f\"\n", touch_pow_mult->value );
				filesystem->FPrintf( f, "touch_exp_mult \"%f\"\n", touch_exp_mult->value );*/
		filesystem->FPrintf(f, "\n// grid settings\n");
		filesystem->FPrintf(f, "touch_grid_count \"%d\"\n", touch_grid_count.GetInt());
		filesystem->FPrintf(f, "touch_grid_enable \"%d\"\n", touch_grid_enable.GetInt());

		filesystem->FPrintf(f, "touch_setgridcolor \"%d\" \"%d\" \"%d\" \"%d\"\n", gridcolor.r, gridcolor.g, gridcolor.b, gridcolor.a);
		filesystem->FPrintf(f, "touch_button_info \"%d\"\n", touch_button_info.GetInt());
		/*
				filesystem->FPrintf( f, "\n// global overstroke (width, r, g, b, a)\n" );
				filesystem->FPrintf( f, "touch_set_stroke %d %d %d %d %d\n", touch.swidth, touch.scolor[0], touch.scolor[1], touch.scolor[2], touch.scolor[3] );
				filesystem->FPrintf( f, "\n// highlight when pressed\n" );
				filesystem->FPrintf( f, "touch_highlight_r \"%f\"\n", touch_highlight_r->value );
				filesystem->FPrintf( f, "touch_highlight_g \"%f\"\n", touch_highlight_g->value );
				filesystem->FPrintf( f, "touch_highlight_b \"%f\"\n", touch_highlight_b->value );
				filesystem->FPrintf( f, "touch_highlight_a \"%f\"\n", touch_highlight_a->value );
				filesystem->FPrintf( f, "\n// _joy and _dpad options\n" );
				filesystem->FPrintf( f, "touch_dpad_radius \"%f\"\n", touch_dpad_radius->value );
				filesystem->FPrintf( f, "touch_joy_radius \"%f\"\n", touch_joy_radius->value );
		*/
		filesystem->FPrintf(f, "\n// how much slowdown when Precise Look button pressed\n");
		filesystem->FPrintf(f, "touch_precise_amount \"%f\"\n", touch_precise_amount.GetFloat());
		//		filesystem->FPrintf( f, "\n// enable/disable move indicator\n" );
		//		filesystem->FPrintf( f, "touch_move_indicator \"%f\"\n", touch_move_indicator );

		filesystem->FPrintf(f, "\n// reset menu state when execing config\n");
		//filesystem->FPrintf( f, "touch_setclientonly 0\n" );
		filesystem->FPrintf(f, "\n// touch buttons\n");
		filesystem->FPrintf(f, "touch_removeall\n");

		CUtlLinkedList<CTouchButton*>::iterator it;
		for (it = btns.begin(); it != btns.end(); it++)
		{
			CTouchButton* b = *it;

			if (b->flags & TOUCH_FL_CLIENT)
				continue; //skip temporary buttons

			if (b->flags & TOUCH_FL_DEF_SHOW)
				b->flags &= ~TOUCH_FL_HIDE;

			if (b->flags & TOUCH_FL_DEF_HIDE)
				b->flags |= TOUCH_FL_HIDE;

			float aspect = (b->y2 - b->y1) / ((b->x2 - b->x1) / (screen_h / screen_w));

			filesystem->FPrintf(f, "touch_addbutton \"%s\" \"%s\" \"%s\" %f %f %f %f %d %d %d %d %d %f\n",
				b->name, b->texturefile, b->command,
				b->x1, b->y1, b->x2, b->y2,
				b->color.r, b->color.g, b->color.b, b->color.a, b->flags, aspect);
		}

		filesystem->Close(f);

		filesystem->RemoveFile(oldconfigfile);
		filesystem->RenameFile(configfile, oldconfigfile);
		filesystem->RenameFile(newconfigfile, configfile);
	}
	else DevMsg("Couldn't write %s.\n", configfile);
}
```

stb_rect_pack.h
```cpp
// stb_rect_pack.h - v1.01 - public domain - rectangle packing
// Sean Barrett 2014
//
// Useful for e.g. packing rectangular textures into an atlas.
// Does not do rotation.
//
// Before #including,
//
//    #define STB_RECT_PACK_IMPLEMENTATION
//
// in the file that you want to have the implementation.
//
// Not necessarily the awesomest packing method, but better than
// the totally naive one in stb_truetype (which is primarily what
// this is meant to replace).
//
// Has only had a few tests run, may have issues.
//
// More docs to come.
//
// No memory allocations; uses qsort() and assert() from stdlib.
// Can override those by defining STBRP_SORT and STBRP_ASSERT.
//
// This library currently uses the Skyline Bottom-Left algorithm.
//
// Please note: better rectangle packers are welcome! Please
// implement them to the same API, but with a different init
// function.
//
// Credits
//
//  Library
//    Sean Barrett
//  Minor features
//    Martins Mozeiko
//    github:IntellectualKitty
//
//  Bugfixes / warning fixes
//    Jeremy Jaussaud
//    Fabian Giesen
//
// Version history:
//
//     1.01  (2021-07-11)  always use large rect mode, expose STBRP__MAXVAL in public section
//     1.00  (2019-02-25)  avoid small space waste; gracefully fail too-wide rectangles
//     0.99  (2019-02-07)  warning fixes
//     0.11  (2017-03-03)  return packing success/fail result
//     0.10  (2016-10-25)  remove cast-away-const to avoid warnings
//     0.09  (2016-08-27)  fix compiler warnings
//     0.08  (2015-09-13)  really fix bug with empty rects (w=0 or h=0)
//     0.07  (2015-09-13)  fix bug with empty rects (w=0 or h=0)
//     0.06  (2015-04-15)  added STBRP_SORT to allow replacing qsort
//     0.05:  added STBRP_ASSERT to allow replacing assert
//     0.04:  fixed minor bug in STBRP_LARGE_RECTS support
//     0.01:  initial release
//
// LICENSE
//
//   See end of file for license information.

//////////////////////////////////////////////////////////////////////////////
//
//       INCLUDE SECTION
//

#ifndef STB_INCLUDE_STB_RECT_PACK_H
#define STB_INCLUDE_STB_RECT_PACK_H

#define STB_RECT_PACK_VERSION  1

#ifdef STBRP_STATIC
#define STBRP_DEF static
#else
#define STBRP_DEF extern
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct stbrp_context stbrp_context;
typedef struct stbrp_node    stbrp_node;
typedef struct stbrp_rect    stbrp_rect;

typedef int            stbrp_coord;

#define STBRP__MAXVAL  0x7fffffff
// Mostly for internal use, but this is the maximum supported coordinate value.

STBRP_DEF int stbrp_pack_rects (stbrp_context *context, stbrp_rect *rects, int num_rects);
// Assign packed locations to rectangles. The rectangles are of type
// 'stbrp_rect' defined below, stored in the array 'rects', and there
// are 'num_rects' many of them.
//
// Rectangles which are successfully packed have the 'was_packed' flag
// set to a non-zero value and 'x' and 'y' store the minimum location
// on each axis (i.e. bottom-left in cartesian coordinates, top-left
// if you imagine y increasing downwards). Rectangles which do not fit
// have the 'was_packed' flag set to 0.
//
// You should not try to access the 'rects' array from another thread
// while this function is running, as the function temporarily reorders
// the array while it executes.
//
// To pack into another rectangle, you need to call stbrp_init_target
// again. To continue packing into the same rectangle, you can call
// this function again. Calling this multiple times with multiple rect
// arrays will probably produce worse packing results than calling it
// a single time with the full rectangle array, but the option is
// available.
//
// The function returns 1 if all of the rectangles were successfully
// packed and 0 otherwise.

struct stbrp_rect
{
   // reserved for your use:
   int            id;

   // input:
   stbrp_coord    w, h;

   // output:
   stbrp_coord    x, y;
   int            was_packed;  // non-zero if valid packing

}; // 16 bytes, nominally


STBRP_DEF void stbrp_init_target (stbrp_context *context, int width, int height, stbrp_node *nodes, int num_nodes);
// Initialize a rectangle packer to:
//    pack a rectangle that is 'width' by 'height' in dimensions
//    using temporary storage provided by the array 'nodes', which is 'num_nodes' long
//
// You must call this function every time you start packing into a new target.
//
// There is no "shutdown" function. The 'nodes' memory must stay valid for
// the following stbrp_pack_rects() call (or calls), but can be freed after
// the call (or calls) finish.
//
// Note: to guarantee best results, either:
//       1. make sure 'num_nodes' >= 'width'
//   or  2. call stbrp_allow_out_of_mem() defined below with 'allow_out_of_mem = 1'
//
// If you don't do either of the above things, widths will be quantized to multiples
// of small integers to guarantee the algorithm doesn't run out of temporary storage.
//
// If you do #2, then the non-quantized algorithm will be used, but the algorithm
// may run out of temporary storage and be unable to pack some rectangles.

STBRP_DEF void stbrp_setup_allow_out_of_mem (stbrp_context *context, int allow_out_of_mem);
// Optionally call this function after init but before doing any packing to
// change the handling of the out-of-temp-memory scenario, described above.
// If you call init again, this will be reset to the default (false).


STBRP_DEF void stbrp_setup_heuristic (stbrp_context *context, int heuristic);
// Optionally select which packing heuristic the library should use. Different
// heuristics will produce better/worse results for different data sets.
// If you call init again, this will be reset to the default.

enum
{
   STBRP_HEURISTIC_Skyline_default=0,
   STBRP_HEURISTIC_Skyline_BL_sortHeight = STBRP_HEURISTIC_Skyline_default,
   STBRP_HEURISTIC_Skyline_BF_sortHeight
};


//////////////////////////////////////////////////////////////////////////////
//
// the details of the following structures don't matter to you, but they must
// be visible so you can handle the memory allocations for them

struct stbrp_node
{
   stbrp_coord  x,y;
   stbrp_node  *next;
};

struct stbrp_context
{
   int width;
   int height;
   int align;
   int init_mode;
   int heuristic;
   int num_nodes;
   stbrp_node *active_head;
   stbrp_node *free_head;
   stbrp_node extra[2]; // we allocate two extra nodes so optimal user-node-count is 'width' not 'width+2'
};

#ifdef __cplusplus
}
#endif

#endif

//////////////////////////////////////////////////////////////////////////////
//
//     IMPLEMENTATION SECTION
//

#ifdef STB_RECT_PACK_IMPLEMENTATION
#ifndef STBRP_SORT
#include <stdlib.h>
#define STBRP_SORT qsort
#endif

#ifndef STBRP_ASSERT
#include <assert.h>
#define STBRP_ASSERT assert
#endif

#ifdef _MSC_VER
#define STBRP__NOTUSED(v)  (void)(v)
#define STBRP__CDECL       __cdecl
#else
#define STBRP__NOTUSED(v)  (void)sizeof(v)
#define STBRP__CDECL
#endif

enum
{
   STBRP__INIT_skyline = 1
};

STBRP_DEF void stbrp_setup_heuristic(stbrp_context *context, int heuristic)
{
   switch (context->init_mode) {
      case STBRP__INIT_skyline:
         STBRP_ASSERT(heuristic == STBRP_HEURISTIC_Skyline_BL_sortHeight || heuristic == STBRP_HEURISTIC_Skyline_BF_sortHeight);
         context->heuristic = heuristic;
         break;
      default:
         STBRP_ASSERT(0);
   }
}

STBRP_DEF void stbrp_setup_allow_out_of_mem(stbrp_context *context, int allow_out_of_mem)
{
   if (allow_out_of_mem)
      // if it's ok to run out of memory, then don't bother aligning them;
      // this gives better packing, but may fail due to OOM (even though
      // the rectangles easily fit). @TODO a smarter approach would be to only
      // quantize once we've hit OOM, then we could get rid of this parameter.
      context->align = 1;
   else {
      // if it's not ok to run out of memory, then quantize the widths
      // so that num_nodes is always enough nodes.
      //
      // I.e. num_nodes * align >= width
      //                  align >= width / num_nodes
      //                  align = ceil(width/num_nodes)

      context->align = (context->width + context->num_nodes-1) / context->num_nodes;
   }
}

STBRP_DEF void stbrp_init_target(stbrp_context *context, int width, int height, stbrp_node *nodes, int num_nodes)
{
   int i;

   for (i=0; i < num_nodes-1; ++i)
      nodes[i].next = &nodes[i+1];
   nodes[i].next = NULL;
   context->init_mode = STBRP__INIT_skyline;
   context->heuristic = STBRP_HEURISTIC_Skyline_default;
   context->free_head = &nodes[0];
   context->active_head = &context->extra[0];
   context->width = width;
   context->height = height;
   context->num_nodes = num_nodes;
   stbrp_setup_allow_out_of_mem(context, 0);

   // node 0 is the full width, node 1 is the sentinel (lets us not store width explicitly)
   context->extra[0].x = 0;
   context->extra[0].y = 0;
   context->extra[0].next = &context->extra[1];
   context->extra[1].x = (stbrp_coord) width;
   context->extra[1].y = (1<<30);
   context->extra[1].next = NULL;
}

// find minimum y position if it starts at x1
static int stbrp__skyline_find_min_y(stbrp_context *c, stbrp_node *first, int x0, int width, int *pwaste)
{
   stbrp_node *node = first;
   int x1 = x0 + width;
   int min_y, visited_width, waste_area;

   STBRP__NOTUSED(c);

   STBRP_ASSERT(first->x <= x0);

   #if 0
   // skip in case we're past the node
   while (node->next->x <= x0)
      ++node;
   #else
   STBRP_ASSERT(node->next->x > x0); // we ended up handling this in the caller for efficiency
   #endif

   STBRP_ASSERT(node->x <= x0);

   min_y = 0;
   waste_area = 0;
   visited_width = 0;
   while (node->x < x1) {
      if (node->y > min_y) {
         // raise min_y higher.
         // we've accounted for all waste up to min_y,
         // but we'll now add more waste for everything we've visted
         waste_area += visited_width * (node->y - min_y);
         min_y = node->y;
         // the first time through, visited_width might be reduced
         if (node->x < x0)
            visited_width += node->next->x - x0;
         else
            visited_width += node->next->x - node->x;
      } else {
         // add waste area
         int under_width = node->next->x - node->x;
         if (under_width + visited_width > width)
            under_width = width - visited_width;
         waste_area += under_width * (min_y - node->y);
         visited_width += under_width;
      }
      node = node->next;
   }

   *pwaste = waste_area;
   return min_y;
}

typedef struct
{
   int x,y;
   stbrp_node **prev_link;
} stbrp__findresult;

static stbrp__findresult stbrp__skyline_find_best_pos(stbrp_context *c, int width, int height)
{
   int best_waste = (1<<30), best_x, best_y = (1 << 30);
   stbrp__findresult fr;
   stbrp_node **prev, *node, *tail, **best = NULL;

   // align to multiple of c->align
   width = (width + c->align - 1);
   width -= width % c->align;
   STBRP_ASSERT(width % c->align == 0);

   // if it can't possibly fit, bail immediately
   if (width > c->width || height > c->height) {
      fr.prev_link = NULL;
      fr.x = fr.y = 0;
      return fr;
   }

   node = c->active_head;
   prev = &c->active_head;
   while (node->x + width <= c->width) {
      int y,waste;
      y = stbrp__skyline_find_min_y(c, node, node->x, width, &waste);
      if (c->heuristic == STBRP_HEURISTIC_Skyline_BL_sortHeight) { // actually just want to test BL
         // bottom left
         if (y < best_y) {
            best_y = y;
            best = prev;
         }
      } else {
         // best-fit
         if (y + height <= c->height) {
            // can only use it if it first vertically
            if (y < best_y || (y == best_y && waste < best_waste)) {
               best_y = y;
               best_waste = waste;
               best = prev;
            }
         }
      }
      prev = &node->next;
      node = node->next;
   }

   best_x = (best == NULL) ? 0 : (*best)->x;

   // if doing best-fit (BF), we also have to try aligning right edge to each node position
   //
   // e.g, if fitting
   //
   //     ____________________
   //    |____________________|
   //
   //            into
   //
   //   |                         |
   //   |             ____________|
   //   |____________|
   //
   // then right-aligned reduces waste, but bottom-left BL is always chooses left-aligned
   //
   // This makes BF take about 2x the time

   if (c->heuristic == STBRP_HEURISTIC_Skyline_BF_sortHeight) {
      tail = c->active_head;
      node = c->active_head;
      prev = &c->active_head;
      // find first node that's admissible
      while (tail->x < width)
         tail = tail->next;
      while (tail) {
         int xpos = tail->x - width;
         int y,waste;
         STBRP_ASSERT(xpos >= 0);
         // find the left position that matches this
         while (node->next->x <= xpos) {
            prev = &node->next;
            node = node->next;
         }
         STBRP_ASSERT(node->next->x > xpos && node->x <= xpos);
         y = stbrp__skyline_find_min_y(c, node, xpos, width, &waste);
         if (y + height <= c->height) {
            if (y <= best_y) {
               if (y < best_y || waste < best_waste || (waste==best_waste && xpos < best_x)) {
                  best_x = xpos;
                  STBRP_ASSERT(y <= best_y);
                  best_y = y;
                  best_waste = waste;
                  best = prev;
               }
            }
         }
         tail = tail->next;
      }
   }

   fr.prev_link = best;
   fr.x = best_x;
   fr.y = best_y;
   return fr;
}

static stbrp__findresult stbrp__skyline_pack_rectangle(stbrp_context *context, int width, int height)
{
   // find best position according to heuristic
   stbrp__findresult res = stbrp__skyline_find_best_pos(context, width, height);
   stbrp_node *node, *cur;

   // bail if:
   //    1. it failed
   //    2. the best node doesn't fit (we don't always check this)
   //    3. we're out of memory
   if (res.prev_link == NULL || res.y + height > context->height || context->free_head == NULL) {
      res.prev_link = NULL;
      return res;
   }

   // on success, create new node
   node = context->free_head;
   node->x = (stbrp_coord) res.x;
   node->y = (stbrp_coord) (res.y + height);

   context->free_head = node->next;

   // insert the new node into the right starting point, and
   // let 'cur' point to the remaining nodes needing to be
   // stiched back in

   cur = *res.prev_link;
   if (cur->x < res.x) {
      // preserve the existing one, so start testing with the next one
      stbrp_node *next = cur->next;
      cur->next = node;
      cur = next;
   } else {
      *res.prev_link = node;
   }

   // from here, traverse cur and free the nodes, until we get to one
   // that shouldn't be freed
   while (cur->next && cur->next->x <= res.x + width) {
      stbrp_node *next = cur->next;
      // move the current node to the free list
      cur->next = context->free_head;
      context->free_head = cur;
      cur = next;
   }

   // stitch the list back in
   node->next = cur;

   if (cur->x < res.x + width)
      cur->x = (stbrp_coord) (res.x + width);

#ifdef _DEBUG
   cur = context->active_head;
   while (cur->x < context->width) {
      STBRP_ASSERT(cur->x < cur->next->x);
      cur = cur->next;
   }
   STBRP_ASSERT(cur->next == NULL);

   {
      int count=0;
      cur = context->active_head;
      while (cur) {
         cur = cur->next;
         ++count;
      }
      cur = context->free_head;
      while (cur) {
         cur = cur->next;
         ++count;
      }
      STBRP_ASSERT(count == context->num_nodes+2);
   }
#endif

   return res;
}

static int STBRP__CDECL rect_height_compare(const void *a, const void *b)
{
   const stbrp_rect *p = (const stbrp_rect *) a;
   const stbrp_rect *q = (const stbrp_rect *) b;
   if (p->h > q->h)
      return -1;
   if (p->h < q->h)
      return  1;
   return (p->w > q->w) ? -1 : (p->w < q->w);
}

static int STBRP__CDECL rect_original_order(const void *a, const void *b)
{
   const stbrp_rect *p = (const stbrp_rect *) a;
   const stbrp_rect *q = (const stbrp_rect *) b;
   return (p->was_packed < q->was_packed) ? -1 : (p->was_packed > q->was_packed);
}

STBRP_DEF int stbrp_pack_rects(stbrp_context *context, stbrp_rect *rects, int num_rects)
{
   int i, all_rects_packed = 1;

   // we use the 'was_packed' field internally to allow sorting/unsorting
   for (i=0; i < num_rects; ++i) {
      rects[i].was_packed = i;
   }

   // sort according to heuristic
   STBRP_SORT(rects, num_rects, sizeof(rects[0]), rect_height_compare);

   for (i=0; i < num_rects; ++i) {
      if (rects[i].w == 0 || rects[i].h == 0) {
         rects[i].x = rects[i].y = 0;  // empty rect needs no space
      } else {
         stbrp__findresult fr = stbrp__skyline_pack_rectangle(context, rects[i].w, rects[i].h);
         if (fr.prev_link) {
            rects[i].x = (stbrp_coord) fr.x;
            rects[i].y = (stbrp_coord) fr.y;
         } else {
            rects[i].x = rects[i].y = STBRP__MAXVAL;
         }
      }
   }

   // unsort
   STBRP_SORT(rects, num_rects, sizeof(rects[0]), rect_original_order);

   // set was_packed flags and all_rects_packed status
   for (i=0; i < num_rects; ++i) {
      rects[i].was_packed = !(rects[i].x == STBRP__MAXVAL && rects[i].y == STBRP__MAXVAL);
      if (!rects[i].was_packed)
         all_rects_packed = 0;
   }

   // return the all_rects_packed status
   return all_rects_packed;
}
#endif

/*
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2017 Sean Barrett
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
*/
```
---
# This Project is Licensed under MIT License (please credit me if you do use this project)
