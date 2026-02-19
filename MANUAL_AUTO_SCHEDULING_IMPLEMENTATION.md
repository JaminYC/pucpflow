# 📅 Manual and Auto-Scheduling Implementation

## ✅ Implementation Complete

This document describes the newly implemented manual and automatic scheduling features for Google Calendar integration.

---

## 🎯 Features Implemented

### 1. **Manual Scheduling Button** ✅
- User manually selects date and time for a task
- Automatically segments tasks longer than 2 hours into multiple sessions
- Creates Google Calendar events for each session
- Updates `fechaProgramada` field in the task

### 2. **Auto-Scheduling Button** ✅
- System automatically searches for free slots in Google Calendar
- Searches next 14 days, 9 AM - 5 PM, weekdays only
- Uses 30-minute intervals for slot detection
- Shows confirmation dialog with proposed time before scheduling
- User must confirm before creating the event

### 3. **Task Segmentation** ✅
- Tasks longer than 120 minutes are automatically segmented
- Each session is maximum 2 hours (120 minutes)
- Sessions are created with 15-minute buffer between them
- Session titles include "(Sesión X/Y)" suffix

---

## 📂 Files Modified

### 1. `google_calendar_service.dart`

**New Methods:**

```dart
List<int> segmentarTarea(int duracionTotalMinutos)
```
- Segments a task into sessions of max 120 minutes
- Returns list of durations for each session

```dart
Future<Map<String, dynamic>> agendarTareaManualmente({
  required Tarea tarea,
  required DateTime fechaHoraInicio,
  required String responsableUid,
})
```
- Schedules task manually at user-selected time
- Creates multiple events if task is segmented
- Returns success status and list of event IDs

```dart
Future<Map<String, dynamic>> buscarSlotAutomatico({
  required Tarea tarea,
  required String responsableUid,
})
```
- Searches for first available free slot
- Returns proposed slot for user confirmation
- Does NOT create events yet (waits for confirmation)

```dart
Future<Map<String, dynamic>> confirmarAgendaAutomatica({
  required Tarea tarea,
  required DateTime fechaHoraInicio,
  required String responsableUid,
})
```
- Confirms and creates events after user approval
- Uses same logic as manual scheduling

**Helper Method:**
```dart
String _formatearFecha(DateTime fecha)
```
- Formats date in Spanish: "lunes 15 de enero a las 14:30"

---

### 2. `TareaFormWidget.dart`

**New UI Components:**

- **Calendar Scheduling Section**: Appears when task has responsables and duration > 0
- **Two Action Buttons**:
  - "Agendar Manualmente" (Blue) - Opens date/time picker
  - "Agendar Automático" (Green) - Searches for free slot
- **Duration Info**: Shows if task will be segmented

**New Methods:**

```dart
Future<void> _agendarManualmente()
```
- Validates task has title and responsables
- Shows date picker → time picker
- Calls `agendarTareaManualmente()`
- Updates `fechaProgramada` on success
- Shows success/error feedback

```dart
Future<void> _agendarAutomaticamente()
```
- Validates task has title and responsables
- Shows loading dialog while searching
- Calls `buscarSlotAutomatico()`
- Shows confirmation dialog with proposed time
- If confirmed, calls `confirmarAgendaAutomatica()`
- Updates `fechaProgramada` on success
- Shows success/error feedback

---

## 🔄 User Flow

### Manual Scheduling Flow:

```
User clicks "Agendar Manualmente"
    ↓
Validates title and responsables
    ↓
Date picker opens
    ↓
Time picker opens
    ↓
Loading dialog appears
    ↓
Segments task if > 120 min
    ↓
Creates Google Calendar event(s)
    ↓
Updates fechaProgramada
    ↓
Shows success message: "✅ Tarea agendada en X sesiones"
```

### Auto-Scheduling Flow:

```
User clicks "Agendar Automático"
    ↓
Validates title and responsables
    ↓
Shows "Buscando espacio disponible..."
    ↓
Searches calendar for free slots (14 days)
    ↓
Finds first available slot
    ↓
Shows confirmation dialog:
"Se agendará el lunes 15 de enero a las 14:30. ¿Confirmar?"
    ↓
User clicks "Confirmar"
    ↓
Loading dialog appears
    ↓
Segments task if > 120 min
    ↓
Creates Google Calendar event(s)
    ↓
Updates fechaProgramada
    ↓
Shows success message: "✅ Tarea agendada en X sesiones"
```

---

## 📊 Task Segmentation Examples

### Example 1: 90-minute task
- **Segments**: 1 session (90 min)
- **Events created**: 1
- **Title**: "Preparar presentación"

### Example 2: 180-minute task
- **Segments**: 2 sessions (120 min + 60 min)
- **Events created**: 2
- **Titles**:
  - "Preparar presentación (Sesión 1/2)" - 120 min
  - "Preparar presentación (Sesión 2/2)" - 60 min
- **Schedule**:
  - Session 1: 14:00 - 16:00
  - Session 2: 16:15 - 17:15 (15-min buffer)

### Example 3: 300-minute task
- **Segments**: 3 sessions (120 min + 120 min + 60 min)
- **Events created**: 3
- **Schedule**:
  - Session 1: 09:00 - 11:00
  - Session 2: 11:15 - 13:15
  - Session 3: 13:30 - 14:30

---

## ⚙️ Configuration

### Auto-Scheduling Parameters:

| Parameter | Value | Location |
|-----------|-------|----------|
| Search window | 14 days | `buscarSlotAutomatico()` line 590 |
| Working hours | 9 AM - 5 PM | `buscarSlotAutomatico()` line 610 |
| Slot interval | 30 minutes | `buscarSlotAutomatico()` line 611 |
| Working days | Mon - Fri | `buscarSlotAutomatico()` line 605 |
| Max session | 120 minutes | `segmentarTarea()` line 458 |
| Session buffer | 15 minutes | `agendarTareaManualmente()` line 529 |

---

## 🎨 UI Details

### Buttons Appearance:

**Manual Button (Blue)**:
- Icon: 📅 (Calendar icon)
- Label: "Agendar Manualmente"
- Color: Blue (#2196F3)
- Action: Opens date/time picker

**Auto Button (Green)**:
- Icon: ✨ (Auto-fix icon)
- Label: "Agendar Automático"
- Color: Green (#4CAF50)
- Action: Searches calendar and shows confirmation

### Visibility Conditions:

Buttons only appear when:
1. Task has at least one responsable assigned
2. Task duration > 0 minutes

### Duration Info Text:

- **Short tasks (≤120 min)**: "⏱️ Duración: 90 minutos"
- **Long tasks (>120 min)**: "⏱️ Tarea de 180 min se segmentará en sesiones de máx. 2 horas"

---

## 🔐 Validation & Error Handling

### Validations:

1. **Before scheduling**:
   - Task must have a title
   - Task must have at least one responsable
   - User must be authenticated

2. **During scheduling**:
   - Google Calendar connection must succeed
   - User email must exist in Firestore
   - For auto-schedule: Free slot must be found

### Error Messages:

| Error | Message |
|-------|---------|
| No title | "⚠️ Primero ingresa un título para la tarea" |
| No responsables | "⚠️ Asigna al menos un responsable antes de agendar" |
| Not authenticated | "❌ Usuario no autenticado" |
| Calendar error | "❌ No se pudo conectar con Google Calendar" |
| No slots found | "❌ No se encontraron slots disponibles en los próximos 14 días" |

### Success Messages:

| Case | Message |
|------|---------|
| Single session | "✅ Tarea agendada en Google Calendar" |
| Multiple sessions | "✅ Tarea agendada en 3 sesiones" |

---

## 🧪 Testing Checklist

- [ ] Manual scheduling with task < 2 hours
- [ ] Manual scheduling with task > 2 hours (verify segmentation)
- [ ] Auto-scheduling with available slots
- [ ] Auto-scheduling when no slots available
- [ ] User cancels auto-scheduling confirmation
- [ ] Scheduling without responsables (should show warning)
- [ ] Scheduling without title (should show warning)
- [ ] Google Calendar offline (should show error)
- [ ] Verify events appear in Google Calendar
- [ ] Verify `fechaProgramada` is updated
- [ ] Verify segmented sessions have correct titles
- [ ] Verify 15-minute buffer between sessions

---

## 🚫 Deferred Feature

**Redistribute All Tasks Button**: NOT implemented (per user request)
- Reason: Could generate errors if not done correctly
- Would redistribute all pending tasks automatically
- Would monitor and re-redistribute incomplete tasks
- Marked for future implementation

---

## 📝 Important Notes

1. **Event Privacy**: All events are created as `private` and `visibility: "private"`
2. **No Invitations**: Events use `sendUpdates: "none"` to prevent email notifications
3. **Silent Login**: Uses `silentOnly: true` for Google sign-in to avoid prompts
4. **Timezone**: All events use "America/Lima" timezone
5. **Event Properties**: Events are marked as `opaque` (blocks time) and guests cannot modify

---

## 🔗 Related Documentation

- [GOOGLE_CALENDAR_INTEGRATION.md](GOOGLE_CALENDAR_INTEGRATION.md) - Full integration guide
- [tarea_model.dart](lib/features/user_auth/presentation/pages/Proyectos/tarea_model.dart) - Task model with new fields
- [google_calendar_service.dart](lib/features/user_auth/presentation/pages/Login/google_calendar_service.dart) - Calendar service

---

**Implementation Date**: January 2025
**Version**: 1.0.0
**Status**: ✅ Complete and Ready for Testing
