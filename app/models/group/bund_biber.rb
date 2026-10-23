# frozen_string_literal: true

#  Copyright (c) 2026, Deutsche Pfadfinder*innenschaft Sankt Georg. This file is part of
#  hitobito_dpsg and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dpsg.

class Group::BundBiber < Group::BundArbeitsbereich
  ### ROLES

  class Beauftragt < ::Role
    self.permissions = [:layer_and_below_read, :contact_data]
    self.sgbviii_required = true
  end

  class AKLeitung < ::Role
    self.permissions = [:group_and_below_read, :contact_data]
    self.sgbviii_required = true
  end

  class AKMitarbeiter < ::Role
    self.permissions = [:group_and_below_read]
    self.sgbviii_required = true
  end

  class AKFreierMitarbeiter < ::Role
    self.permissions = []
  end

  roles Beauftragt,
    AKLeitung,
    AKMitarbeiter,
    AKFreierMitarbeiter
end
