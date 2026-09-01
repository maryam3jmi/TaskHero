import 'package:flutter/material.dart';
import 'child/childLoginPage.dart';
import 'parent/parentLoginPage.dart';
//import 'Chat_page.dart';

class mainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFA9CDE3),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 250),
                // Parent Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParentLoginPage(),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(300, 60),
                    backgroundColor: Color(0xFFF9CF45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Parent",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),

                SizedBox(height: 30), // space between buttons
                // Child Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Childloginpage()),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(300, 60),
                    backgroundColor: Color(0xFFF9CF45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "Child",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),

                Spacer(),

                SizedBox(height: 60), // space between buttons and image60
                // Image below the buttons
                Image.asset(
                  'assets/icon.png', // replace with your image path
                  width: 300, // set desired width
                  height: 300, // set desired height
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
