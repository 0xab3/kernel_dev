pub fn is_in_range(start: anytype, end: @TypeOf(start), value: @TypeOf(start)) bool {
    return start <= value and value <= end; 
}
