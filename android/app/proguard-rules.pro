# Keep the no-argument constructor required by Room reflection under AGP 9 / R8 full mode
# (transitive room-runtime 2.2.5 via work-runtime 2.7.0 omits <init>() in its consumer rules).
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
