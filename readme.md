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
3. Make your vcxproj compile for shared library (`.so`). rename it from `.vcxproj` to `.vcxitems` and add somewhere in the beginning
```xml
    <HasSharedItems>true</HasSharedItems>
```

4. In `cdll_client_int.cpp` include `touch.h` and in line 732 delete `public` and under it Add the following code
```cpp
virtual void IN_TouchEvent( int type, int fingerId, int x, int y );
```
In line 1044 add 	`gTouch.Init();`, Line 1422 right above `void CHLClient::ExtraMouseSample( float frametime, bool active )` add
```cpp
void CHLClient::IN_TouchEvent( int type, int fingerId, int x, int y )
{
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
5. In in_main.cpp, include `touch.h`,`ienginevgui.h`, and `inputsystem/iinputsystem.h` and in line 953 add
```cpp
gTouch.Move( frametime, cmd );
```
in line 1200, change 
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
6. in vgui_int.cpp include touch.h and in line 133 add
```cpp
	touch_panel->Destroy();
```
then in line 147
```cpp
touch_panel->Create( toolParent );
```
then in line 213
```cpp
touch_panel->Create( toolParent );
```
then in line 244
```cpp
touch_panel->Destroy();
```

in cdll_int.h add `virtual void IN_TouchEvent( int type, int fingerId, int x, int y ) = 0;`

7. here are the touch files
- [touch.h](https://github.com/GuestSneezeOSDev/source4android/blob/main/src/game/client/touch.h)
- [touch.cpp](https://github.com/GuestSneezeOSDev/source4android/blob/main/src/game/client/touch.cpp)
# This Project is Licensed under MIT License (please credit me if you do use this project)
