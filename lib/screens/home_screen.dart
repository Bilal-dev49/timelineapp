import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timelineapp/screens/login_screen.dart';
import 'add_timeline_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  giveDate(var timeline) {
    String displayTime;
    var timestampValue = timeline['timestamp'];

    // Check if the timestamp is of type Timestamp
    if (timestampValue is Timestamp) {
      // Convert to DateTime and format it as needed
      displayTime = timestampValue.toDate().toString();
    } else if (timestampValue is String) {
      // If it's a String, you might want to handle it differently or convert it
      displayTime = timestampValue; // or format it appropriately
    } else {
      displayTime = 'Invalid timestamp'; // Handle unexpected types
    }

    print(displayTime);
    // Use the displayTime variable in your Text widget
    return displayTime;
  }

  Future<String> getUserEmail(String uid) async {
    try {
      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['email'] ?? 'No Email'; // Return the email if it exists
      } else {
        return 'User not found'; // If no user found with the given userId
      }
    } catch (e) {
      return 'Error fetching email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timeline'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                // Sign out the user
                await _auth.signOut();

                // Navigate to the login screen and replace the current route
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              } catch (e) {
                print('Error during sign out: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('timelines')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Check for connection state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Check for error state
          if (snapshot.hasError) {
            return Center(
                child: Text('Something went wrong: ${snapshot.error}'));
          }

          // Check if snapshot has data and is not null
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No timelines available.'));
          }

          final timelines = snapshot.data!.docs;

          return timelines.isNotEmpty
              ? ListView.builder(
                  itemCount: timelines.length,
                  itemBuilder: (context, index) {
                    var timeline = timelines[index];
                    var displayDate = giveDate(timeline);
                    var uid = timeline['uid'];

                    return FutureBuilder<String>(
                      future: getUserEmail(uid),
                      builder: (context, emailSnapshot) {
                        if (emailSnapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            title: Text(timeline['timelineContent']),
                            subtitle: Text('Loading email...'),
                          );
                        }
                        if (emailSnapshot.hasError) {
                          return ListTile(
                            title: Text(timeline['timelineContent']),
                            subtitle: Text('Error fetching email'),
                          );
                        }
                        var userEmail = emailSnapshot.data ?? 'No Email';
                        return Card(
                          margin: EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(timeline['imageUrl']),
                            ),
                            title: Text(timeline['timelineContent']),
                            subtitle: Text('$displayDate\n$userEmail'), // Display date and email
                          ),
                        );
                      },
                    );
                  },
                )
              : Center(child: Text('No timelines available.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => AddTimelineScreen())),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timelineapp/screens/login_screen.dart';
import 'add_timeline_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  giveDate(var timeline) {
    String displayTime;
    var timestampValue = timeline['timestamp'];

    // Check if the timestamp is of type Timestamp
    if (timestampValue is Timestamp) {
      // Convert to DateTime and format it as needed
      displayTime = timestampValue.toDate().toString();
    } else if (timestampValue is String) {
      // If it's a String, you might want to handle it differently or convert it
      displayTime = timestampValue; // or format it appropriately
    } else {
      displayTime = 'Invalid timestamp'; // Handle unexpected types
    }

    print(displayTime);
    // Use the displayTime variable in your Text widget
    return displayTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timeline'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              try {
                // Sign out the user
                await _auth.signOut();

                // Navigate to the login screen and replace the current route
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              } catch (e) {
                print('Error during sign out: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('timelines',)
            .orderBy('timestamp', descending: true)
            .snapshots(),
            
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Check for connection state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Check for error state
          if (snapshot.hasError) {
            return Center(
                child: Text('Something went wrong: ${snapshot.error}'));
          }

          // Check if snapshot has data and is not null
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No timelines available.'));
          }

          final timelines = snapshot.data!.docs;

          return timelines.isNotEmpty
              ? ListView.builder(
                  itemCount: timelines.length,
                  itemBuilder: (context, index) {
                    var timeline = timelines[index];
                    // Ensure the timeline entry has valid data
                    // if (timeline['timelineContent'] == null ||
                    //     timeline['imageUrl'] == null) {
                    //   return SizedBox
                    //       .shrink(); // Skip rendering for invalid entries
                    // }
                    var displayDate = giveDate(timeline);
                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(timeline['imageUrl']),
                        ),
                        title: Text(timeline['timelineContent']),
                        subtitle: Text(displayDate),
                      ),
                    );
                  },
                )
              : Center(child: Text('No timelines available.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => AddTimelineScreen())),
      ),
    );
  }
}
*/