# frozen_string_literal: true

#  Copyright (c) 2012-2026, Deutsche Pfadfinderschaft Sankt Georg e.V. This file is part of
#  hitobito_dpsg and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dpsg.

class Group::Woelflingsmeute < ::Group
  ### ROLES

  class Leitwoelfling < ::Role
    self.permissions = [:group_read]
    self.sgbviii_required = true
  end

  class LeitwoelflingStv < ::Role
    self.permissions = [:group_read]
    self.sgbviii_required = true
  end

  class Woelfling < ::Role
    self.permissions = []
  end

  roles Leitwoelfling,
    LeitwoelflingStv,
    Woelfling
end
