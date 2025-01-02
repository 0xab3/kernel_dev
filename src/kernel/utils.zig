pub fn is_in_range(start: anytype, end: anytype, value: anytype) bool {
    return start <= value and value <= end;
}
