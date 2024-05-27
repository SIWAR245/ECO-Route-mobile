import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_route_se/Screens/Profile/Team/update_team_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../Common_widgets/toast.dart';
import 'add_team_member.dart';
import 'dart:async';

class Team extends StatefulWidget {
  const Team({super.key});

  @override
  _TeamState createState() => _TeamState();
}

class _TeamState extends State<Team> {

  final CollectionReference _teamMember = FirebaseFirestore.instance.collection("team_members");
  late Stream<QuerySnapshot> _teamMembersStream;
  Color shadow = Colors.grey;

  @override
  void initState() {
    super.initState();
    _teamMembersStream = _teamMember.snapshots();
  }


  Future<void> deleteTeamMember(String memberId) async {
    try {
      await _teamMember.doc(memberId).delete();
      ToastUtils.showToast(
        message: 'Team member deleted successfully',
      );
    } catch (e) {
      ToastUtils.showErrorToast(
        message: 'Error adding team member: $e',
      );
    }
  }

  void updateMember(BuildContext context, String memberId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateMemberForm(memberId: memberId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: Colors.white,
          leading: InkWell(onTap: () {
            Navigator.pop(context);
          },
            child: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.teal,
            ),
          ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _teamMembersStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final List<Widget> teamMembersWidgets =
                snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: shadow.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 2,
                          ),
                        ],
                        // border: Border(
                        //   left: BorderSide(
                        //     color: Colors.teal, // Couleur du bord gauche
                        //     width: 6, // Épaisseur du bord gauche
                        //   ),
                        // ),
                      ),
                      child: Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            Builder(
                              builder: (context) {
                                return ElevatedButton(
                                  onPressed: () {
                                    deleteTeamMember(document.id);
                                    Slidable.of(context)!.close();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.all(10),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                );
                              },
                            ),
                            Builder(
                              builder: (context) {
                                return ElevatedButton(
                                  onPressed: () {
                                    updateMember(context, document.id);
                                    Slidable.of(context)!.close();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.all(10),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        child: Container(
                          height: 100,
                          margin: const EdgeInsets.all(8),
                          child: Center(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  data['profileImageUrl'].toString(),
                                ),
                                radius: 30,
                              ),
                              title: Text(
                                '${data['firstName'] ??
                                    ''} ${data['lastName'] ?? ''}',
                                style: const TextStyle(fontSize: 20),
                              ),
                              subtitle: Text(data['Email'],),
                              trailing: Icon(
                                  Icons.keyboard_arrow_right,
                                color: Colors.grey,
                              ),
                              onTap: () {},
                              tileColor: Colors.white,

                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList();
                return ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  children: teamMembersWidgets,
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMemberForm(),
                    ),
                  );
                },
                backgroundColor: Colors.teal,
                elevation: 1,
                child: Icon(Icons.add, color: Colors.white, size: 32), // Adjust the size as needed
              ),
            ),
          ),
          // const SizedBox(
          //   height: 410,
          // )
        ],
      ),
      // bottomSheet: Container(
      //   width: 360,
      //   height: 380,
      //   decoration: const BoxDecoration(
      //     color: Colors.white,
      //   ),
      //   child: SvgPicture.asset(
      //     'assets/images/aaaa.svg',
      //     fit: BoxFit.fill,
      //   ),
      // ),
      backgroundColor: Colors.white,
    );
  }
}
