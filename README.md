# AuraTrack 🏋️‍♂️

Модерна фитнес апликација изработена со **Flutter** и **Firebase** која им овозможува на корисниците да пребаруваат вежби, да следат тренинзи за сила со тајмер, да снимаат кардио активности со GPS мапа во живо и да ја прегледуваат својата историја на тренинзи и статистики.

---

# Функционалности

## Автентикација
- Регистрација и најава со email и лозинка преку Firebase Authentication
- Ресетирање на лозинка преку email
- Автоматско пренасочување кон login доколку корисникот не е најавен

## Библиотека со вежби
- Пребарување на повеќе од 1300 вежби преку ExerciseDB API (RapidAPI)
- Филтрирање според мускулна група (грб, гради, рамена, раце, нозе итн.)
- Пребарување по име на вежба
- Infinite scroll со пагинација
- Детален приказ за секоја вежба со:
  - Видео демонстрација
  - Инструкции чекор по чекор
  - Совети
  - Варијации
  - Таргетирани мускули

## Тренинзи за сила
- Стартување тренинг со тајмер за било која вежба
- Автоматско пуштање на muted видео за време на тренинг
- Pause / Resume / Cancel функционалности
- Summary екран со:
  - Времетраење
  - Проценети потрошени калории

## Следење на кардио активности (Strava стил)
- Избор помеѓу:
  - Пешачење
  - Трчање
  - Планинарење
  - Велосипедизам
- GPS следење во реално време
- OpenStreetMap мапа
- Live статистики:
  - Време
  - Дистанца
  - Pace (min/km)
- Приказ на рута преку polyline
- Pause / Resume без губење на податоци

## Профил
- Измена на:
  - Име
  - Тежина
  - Висина
  - Возраст
  - Пол
- Поставување профилна слика:
  - Камера
  - Галерија
- Компресирани фотографии зачувани како base64 во Firestore

## Историја и статистики
- Историја на сите тренинзи групирани по датум
- Преглед на рута за кардио активности
- Неделни статистики:
  - Вкупен број тренинзи
  - Активно време
  - Потрошени калории
- Картичка со последен тренинг

## Модерен UI
- Темни gradient header-и
- Конзистентен color system:
  - Портокалова — strength
  - Сина — cardio
  - Виолетова — history
- Reusable widgets
- Responsive layout за Android уреди

---



# Технологии

| Технологија | Наменa |
|---|---|
| **Flutter** | Cross-platform UI framework |
| **Dart** | Програмски јазик |
| **Firebase Auth** | Автентикација |
| **Cloud Firestore** | NoSQL база на податоци |
| **ExerciseDB API** | Библиотека со вежби |
| **OpenStreetMap** | Мапи |
| **Provider** | State management |
| **GoRouter** | Навигација |
| **Geolocator** | GPS tracking |
| **Video Player** | Видео демонстрации |

---

# Архитектура

```text
lib/
├── main.dart
├── firebase_options.dart
│
├── models/
│   ├── app_user.dart
│   ├── exercise.dart
│   ├── cardio_activity.dart
│   ├── workout_session.dart
│   └── route_point.dart
│
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── exercise_api_service.dart
│   ├── location_service.dart
│   └── image_service.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── exercise_provider.dart
│   ├── workout_provider.dart
│   └── stats_provider.dart
│
├── screens/
│   ├── auth/
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── exercises/
│   ├── cardio/
│   └── history_screen.dart
│
├── widgets/
│   ├── app_text_field.dart
│   ├── profile_avatar.dart
│   ├── exercise_video_player.dart
│   ├── route_map.dart
│   └── route_preview.dart
│
└── utils/
    ├── app_router.dart
    ├── validators.dart
    └── formatters.dart
```

---

# Android Permissions

| Permission | Purpose |
|---|---|
| `INTERNET` | API повици, Firebase и мапи |
| `CAMERA` | Профилна слика |
| `ACCESS_FINE_LOCATION` | GPS tracking |
| `ACCESS_COARSE_LOCATION` | Approximate location |
| `ACCESS_BACKGROUND_LOCATION` | Tracking во позадина |

---

# Firestore Data Structure

```text
users/{uid}
├── email
├── displayName
├── photoBase64
├── weightKg
├── heightCm
├── age
├── gender
├── createdAt
│
└── workouts/{sessionId}
    ├── userId
    ├── workoutType
    ├── activityId
    ├── activityName
    ├── startTime
    ├── endTime
    ├── durationSeconds
    ├── distanceMeters
    ├── caloriesBurned
    ├── notes
    └── routePoints
```

---


# Екрани (11 вкупно)

1. Login  
2. Register  
3. Home  
4. Profile  
5. Exercises List  
6. Exercise Detail  
7. Workout Timer  
8. Workout Summary  
9. Cardio Picker  
10. Cardio Tracking  
11. History  

---

