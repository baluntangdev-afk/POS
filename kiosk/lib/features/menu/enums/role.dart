enum Role {
  user('User'),
  admin('Admin'),
  supervisor('Supervisor');

  const Role(this.title);

  final String title;
}
