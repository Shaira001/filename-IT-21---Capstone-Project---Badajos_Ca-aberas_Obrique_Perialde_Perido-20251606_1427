// lib/calendar_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'announcement.dart';

/// A page that shows a TableCalendar with events, and a “Day Events” tab view.
class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with TickerProviderStateMixin {
  // Colors (copy from your AnnouncementsPage or tweak as desired)
  final Color _primaryColor = const Color(0xFF0A2463);
  final Color _accentColor = const Color(0xFF3E92CC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardGradientEnd = const Color(0xFFE9ECEF);
  final Color _errorColor = const Color(0xFFD62839);

  late TabController _tabController;

  late Map<DateTime, List<Announcement>> _events;
  late List<Announcement> _selectedDayEvents;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _isLoading = false;
  late Future<List<Announcement>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _events = {};
    _selectedDayEvents = [];
    _selectedDay = _normalizeDate(DateTime.now());
    _announcementsFuture = _loadAnnouncementsAndInitializeCalendar();
  }

  Future<List<Announcement>> _loadAnnouncementsAndInitializeCalendar() async {
    setState(() => _isLoading = true);
    try {
      final announcements = await getAllAnnouncements();
      _initializeCalendarEvents(announcements);
      return announcements;
    } catch (e) {
      _showMessage('Failed to load announcements: please try again', isError: true);
      return [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initializeCalendarEvents(List<Announcement> announcements) {
    _events = {};
    for (var announcement in announcements) {
      final eventDate = _normalizeDate(announcement.eventDate);
      _events[eventDate] = (_events[eventDate] ?? [])..add(announcement);
    }
    _selectedDayEvents = _events[_selectedDay] ?? [];
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    final normalized = _normalizeDate(day);
    setState(() {
      _selectedDay = normalized;
      _selectedDayEvents = _events[normalized] ?? [];
      _tabController.index = 1;
    });
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? _errorColor : _accentColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.light(
          primary: _primaryColor,
          secondary: _accentColor,
          error: _errorColor,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 2.0, color: _primaryColor),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: const Text('Calendar & Events'),
          backgroundColor: _primaryColor,
        ),
        body: Stack(
          children: [
            // Background gradient (optional)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _backgroundColor.withOpacity(0.9),
                    _backgroundColor.withOpacity(0.7),
                  ],
                  stops: const [0.1, 0.9],
                ),
              ),
            ),

            Column(
              children: [
                _buildCalendarWidget(),
                _buildCalendarFormatSelector(),
                const SizedBox(height: 8),
                _buildTabBar(),
                Expanded(child: _buildTabViews()),
              ],
            ),

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    strokeWidth: 3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarWidget() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, _cardGradientEnd],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TableCalendar<Announcement>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _selectedDay,
          calendarFormat: _calendarFormat,
          onFormatChanged: (fmt) => setState(() => _calendarFormat = fmt),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: _onDaySelected,
          eventLoader: (day) => _events[_normalizeDate(day)] ?? [],
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: _accentColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primaryColor, _accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            markerSize: 8,
            markerDecoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle),
            todayTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            defaultTextStyle: const TextStyle(color: Colors.black87),
            weekendTextStyle: TextStyle(color: Colors.red[400]),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryColor),
            leftChevronIcon: Icon(Icons.chevron_left, color: _primaryColor),
            rightChevronIcon: Icon(Icons.chevron_right, color: _primaryColor),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2)))),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarFormatSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButton<CalendarFormat>(
              value: _calendarFormat,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
              style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500),
              onChanged: (format) => setState(() => _calendarFormat = format!),
              items: const [
                DropdownMenuItem(value: CalendarFormat.month, child: Text('Month')),
                DropdownMenuItem(value: CalendarFormat.twoWeeks, child: Text('2 Weeks')),
                DropdownMenuItem(value: CalendarFormat.week, child: Text('Week')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [_primaryColor, _accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Padding(
              padding: EdgeInsets.only(left: 8, right: 8),
              child: Tab(text: 'All Announcements'),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8, right: 8),
              child: Tab(text: 'Day Events'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        _allAnnouncementsTab(),
        _dayEventsTab(),
      ],
    );
  }

  /// All Announcements Tab (just reuses FutureBuilder to list all announcements)
  Widget _allAnnouncementsTab() {
    return FutureBuilder<List<Announcement>>(
      future: _announcementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: _errorColor, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading announcements',
                  style: TextStyle(color: _errorColor, fontSize: 16),
                ),
              ],
            ),
          );
        } else {
          final announcements = snapshot.data!;
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.announcement, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No announcements available',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              return _buildAnnouncementCard(announcements[index]);
            },
          );
        }
      },
    );
  }

  /// Day Events Tab (shows events on the selected day)
  Widget _dayEventsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.1),
                  _accentColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Events on ${DateFormat('MMMM d, yyyy').format(_selectedDay)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _selectedDayEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No events scheduled',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _selectedDayEvents.length,
                  itemBuilder: (context, index) {
                    return _buildAnnouncementCard(_selectedDayEvents[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 4))],
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ViewAnnouncementPage(announcement: announcement),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, _cardGradientEnd],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (announcement.image?.isNotEmpty ?? false)
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(announcement.image!)),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: _accentColor),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMMM d, yyyy').format(announcement.eventDate),
                            style: TextStyle(color: _accentColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryColor, _accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    announcement.type,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class ViewAnnouncementPage extends StatelessWidget {
  final Announcement announcement;
  const ViewAnnouncementPage({Key? key, required this.announcement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(announcement.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A2463), Color(0xFF3E92CC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (announcement.image?.isNotEmpty ?? false)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(announcement.image!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFE9ECEF)],
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.calendar_today, size: 18, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM d, yyyy').format(announcement.eventDate),
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0A2463), Color(0xFF3E92CC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(announcement.type, style: const TextStyle(color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 16),
                Text('Details', style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(announcement.details ?? '', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black87, height: 1.5)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
