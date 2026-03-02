# WindowsBar

> A minimal, macOS / GNOME-inspired top bar for Windows 11, built with Rainmeter — designed to feel native, fluent, and unmistakably Windows.

![WindowsBar Screenshot 2](https://github.com/user-attachments/assets/c12c8ab8-4d36-46d5-a46e-90a154ad2da6)

![WindowsBar Screenshot 1](https://github.com/user-attachments/assets/1691d40b-7eb3-495f-a135-923f6f2ba61c)

## 🚀 Features

- Native Windows 11 design language
- Multi-monitor support
- Audio device + volume integration
- Hardware monitor support
- Repositioned Start Menu & Notification Center
- Accent-aware styling
- Dock-like taskbar behavior  

## 🧩 Requirements
- Windows 11
- Rainmeter 4.5.23+
- Windhawk 1.7.3+

## 📦 Installation

#### Install Rainmeter 

```
winget install Rainmeter.Rainmeter
```

#### Install WindowsBar

- Download and install the latest release from [Releases](https://github.com/Meti0X7CB/WindowsBar/releases)

#### Install Windhawk

```
winget install RamenSoftware.Windhawk
```

After installing Windhawk, install the required mods listed below.

## 🔧 Required Windhawk Mods & Settings
- Shell Flyout Positions v1.2
  <details>
  <summary>Setting</summary>
  
  ``` 
  notificationCenter:
    horizontalAlignment: right
    horizontalShift: 0
  actionCenter:
    horizontalAlignment: same
    horizontalShift: 0
  startMenu:
    horizontalAlignment: windowsDefault
    horizontalShift: 0
    verticalAlignment: top
    verticalShift: 0
  ```
  
  </details>

- Taskbar Auto-Hide When Maximized v1.2.4
  
  <details>
  <summary>Setting</summary>
  
  ```
  mode: maximized
  foregroundWindowOnly: 0
  excludedPrograms:
    - ''
  primaryMonitorOnly: 0
  oldTaskbarOnWin11: 0
  ```
  
  </details>

- Windows 11 Notification Center Styler v1.4

  <details>
  <summary>Setting</summary>
  
  ```
  theme: ''
  controlStyles:
    - target: ControlCenter.ControlCenterPage
      styles:
        - VerticalAlignment=Stretch
        - RenderTransform:=<RotateTransform Angle="180" />
        - RenderTransformOrigin=0.5,0.5
    - target: ControlCenter.ControlCenterPage > Grid#RootGrid
      styles:
        - VerticalAlignment=Stretch
        - RenderTransform:=<RotateTransform Angle="180" />
        - RenderTransformOrigin=0.5,0.5
    - target: ControlCenter.ControlCenterPage > Grid#RootGrid > Grid#RootContent
      styles:
        - VerticalAlignment=Top
    - target: ActionCenter.NotificationCenterPage > Grid#RootGrid > Grid#RootContent
      styles:
        - RowDefinitions:=<RowDefinitionCollection><RowDefinition Height="Auto"/><RowDefinition Height="500"/></RowDefinitionCollection>
        - VerticalAlignment=Top
        - CornerRadius=10
        - Padding=0,0,0,-33
    - target: ActionCenter.NotificationCenterPage > Grid#RootGrid > Grid#RootContent > Grid#CalendarCenterGrid
      styles:
        - Height=8455
        - Padding=0,0,0,8000
  styleConstants:
    - ''
  themeResourceVariables:
    - ''
  ```
  
  </details>

- Windows 11 Start Menu Styler v1.3.3

  <details>
  <summary>Setting</summary>
  
  ```
  theme: Windows11_Metro10Minimal
  disableNewStartMenuLayout: 1
  controlStyles:
    - target: StartDocked.StartSizingFrame
      styles:
        - RenderTransform:=<RotateTransform Angle="180" />
        - RenderTransformOrigin=0.5,0.5
    - target: Grid#RootContent
      styles:
        - RenderTransform:=<RotateTransform Angle="180" />
        - RenderTransformOrigin=0.5,0.5
    - target: Border#RootGridDropShadow
      styles:
        - RenderTransform:=<RotateTransform Angle="180" />
        - RenderTransformOrigin=0.5,0.5
  webContentStyles:
    - target: ''
      styles:
        - ''
  webContentCustomJs: ''
  styleConstants:
    - ''
  resourceVariables:
    - variableKey: ''
      value: ''
  ```
  </details>

- Windows 11 Taskbar Styler v1.5.2

  <details>
  <summary>Setting</summary>
  
  ```
  theme: DockLike
  controlStyles:
    - target: SystemTray.OmniButton
      styles:
        - Visibility=Collapsed
    - target: Taskbar.ExperienceToggleButton#LaunchListButton[AutomationProperties.AutomationId=StartButton]
      styles:
        - Visibility=Collapsed
  styleConstants:
    - ''
  resourceVariables:
    - variableKey: ''
      value: ''
  ```
  </details>

## 🖥 Recommended Windows Settings

For best results:

- Taskbar → Automatically hide
- Taskbar alignment → Center
- Transparency effects → Enabled
- Animations → Enabled

## 🙏 Credits

- @m417z — Windhawk mods & settings guidance
- @keifufu — WebNowPlaying plugin and their extensive support
- @Kurou-kun — Native GPU monitor plugin
- 

## ⭐ Support the Project

If you like WindowsBar, please consider to staring the repo.
