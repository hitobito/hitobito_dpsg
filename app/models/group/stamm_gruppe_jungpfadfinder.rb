# frozen_string_literal: true

#  Copyright (c) 2026, Deutsche Pfadfinder*innenschaft Sankt Georg. This file is part of
#  hitobito_dpsg and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dpsg

class Group::StammGruppeJungpfadfinder < ::Group
  ### ROLES

  class Leitung < Role
    self.permissions = [:group_read]
    self.sgbviii_required = true
  end

  class Hilfsleitung < Role
    self.permissions = [:group_read]
    self.sgbviii_required = true
  end

  class Mitglied < Role
  end

  roles Leitung, Hilfsleitung, Mitglied
end
