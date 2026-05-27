import 'package:finance_buddy_app/data/db.dart';

abstract class PersonRepository {
  Stream<List<Person>> watchAllPersons();
  Stream<List<Person>> watchByTag(String tag);
  Future<Person?> getPersonById(int id);
  Future<int> createPerson(PersonsCompanion entry);
  Future<void> updatePerson(int id, PersonsCompanion entry);
  Future<void> deletePerson(int id);
  Future<double> getPersonBalance(int personId);
  Stream<double> watchPersonBalance(int personId);
}
