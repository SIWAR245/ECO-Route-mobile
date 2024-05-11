import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_route_se/Screens/Profile/Team/update_team_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
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


  //delete method
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


  //redirection to the update form
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
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.teal,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                elevation: 0,
                side: BorderSide.none,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMemberForm(),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add Your Team Members',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Icon(Icons.chevron_right,color: Colors.white,),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 410,
          )
        ],
      ),
      bottomSheet: Container(
        width: 360,
        height: 380,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SvgPicture.asset(
          'assets/images/aaaa.svg',
          fit: BoxFit.fill,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }


}
