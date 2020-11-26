# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Acqdat.Repo.insert!(%Acqdat.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AcqdatCore.Seed.RoleManagement.{User, Role, App}
alias AcqdatCore.Seed.EntityManagement.{Sensor, Organisation, Asset, Project, SensorsData}
alias AcqdatCore.Seed.Widget

# The order here is important, don't modify it.

Organisation.seed_organisation!()
Role.seed()
User.seed_user!()
Widget.seed()
App.seed()
