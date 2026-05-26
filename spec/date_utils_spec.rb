# frozen_string_literal: true

RSpec.describe DateUtils do
  describe ".days_between" do
    let(:jan1) { Date.new(2024, 1, 1) }
    let(:jan8) { Date.new(2024, 1, 8) }

    it "returns 7 for a week apart" do
      expect(DateUtils.days_between(jan1, jan8)).to eq(7)
    end

    it "returns 0 for the same date" do
      expect(DateUtils.days_between(jan1, jan1)).to eq(0)
    end

    it "returns 365 for a full non-leap year" do
      expect(DateUtils.days_between(Date.new(2023, 1, 1), Date.new(2024, 1, 1))).to eq(365)
    end

    it "returns 366 for a full leap year" do
      expect(DateUtils.days_between(Date.new(2024, 1, 1), Date.new(2025, 1, 1))).to eq(366)
    end
  end

  describe ".add_business_days" do
    # monday 2024-01-08, tuesday 2024-01-09, wednesday 2024-01-10
    # thursday 2024-01-11, friday 2024-01-12
    # saturday 2024-01-13, sunday 2024-01-14, monday 2024-01-15
    let(:monday) { Date.new(2024, 1, 8) }
    let(:friday) { Date.new(2024, 1, 12) }

    context "when n is zero" do
      it "returns the same date" do
        expect(DateUtils.add_business_days(monday, 0)).to eq(monday)
      end
    end

    context "when n is positive" do
      it "adds 1 business day from Monday to Tuesday" do
        expect(DateUtils.add_business_days(monday, 1)).to eq(Date.new(2024, 1, 9))
      end

      it "skips the weekend when adding 3 days from Thursday" do
        expect(DateUtils.add_business_days(Date.new(2024, 1, 11), 3)).to eq(Date.new(2024, 1, 16))
      end

      it "adds 5 business days from Monday landing on the following Monday" do
        expect(DateUtils.add_business_days(monday, 5)).to eq(Date.new(2024, 1, 15))
      end
    end

    context "when n is negative" do
      it "subtracts 1 business day from Friday to Thursday" do
        expect(DateUtils.add_business_days(friday, -1)).to eq(Date.new(2024, 1, 11))
      end

      it "subtracts 3 business days from Monday (crosses weekend back to Wednesday)" do
        expect(DateUtils.add_business_days(monday, -3)).to eq(Date.new(2024, 1, 3))
      end
    end
  end

  describe ".leap_year?" do
    context "when year is not divisible by 4" do
      it "returns false for 2023" do
        expect(DateUtils.leap_year?(2023)).to be_falsy
      end

      it "returns false for 2019" do
        expect(DateUtils.leap_year?(2019)).to be_falsy
      end
    end

    context "when year is divisible by 4 but not 100" do
      it "returns true for 2024" do
        expect(DateUtils.leap_year?(2024)).to be_truthy
      end

      it "returns true for 2020" do
        expect(DateUtils.leap_year?(2020)).to be_truthy
      end
    end

    context "when year is divisible by 100" do
      it "returns false for 1900" do
        expect(DateUtils.leap_year?(1900)).to be_falsy
      end
    end
  end

  describe ".age_in_years" do
    let(:birthdate) { Date.new(1990, 6, 15) }

    context "when birthday has already occurred this year" do
      it "returns the correct age one day after birthday" do
        expect(DateUtils.age_in_years(birthdate, as_of: Date.new(2024, 6, 16))).to eq(34)
      end

      it "returns the correct age on the birthday itself" do
        expect(DateUtils.age_in_years(birthdate, as_of: Date.new(2024, 6, 15))).to eq(34)
      end

      it "returns the correct age at year end" do
        expect(DateUtils.age_in_years(birthdate, as_of: Date.new(2024, 12, 31))).to eq(34)
      end
    end

    context "when birthday has not yet occurred this year" do
      it "returns one less than the year difference one day before birthday" do
        expect(DateUtils.age_in_years(birthdate, as_of: Date.new(2024, 6, 14))).to eq(33)
      end

      it "returns the correct age at the start of the year" do
        expect(DateUtils.age_in_years(Date.new(2000, 1, 1), as_of: Date.new(2024, 1, 1))).to eq(24)
      end
    end
  end

  describe ".next_occurrence_of_weekday" do
    # 2024-01-08 is a Monday (wday=1)
    let(:monday) { Date.new(2024, 1, 8) }

    it "finds the next Wednesday (wday=3) from Monday" do
      expect(DateUtils.next_occurrence_of_weekday(monday, 3)).to eq(Date.new(2024, 1, 10))
    end

    it "finds the next Monday (wday=1) from Wednesday" do
      expect(DateUtils.next_occurrence_of_weekday(Date.new(2024, 1, 10), 1)).to eq(Date.new(2024, 1, 15))
    end

    it "finds the next Sunday (wday=0) from Monday" do
      expect(DateUtils.next_occurrence_of_weekday(monday, 0)).to eq(Date.new(2024, 1, 14))
    end

    it "finds the next Friday from a Tuesday" do
      expect(DateUtils.next_occurrence_of_weekday(Date.new(2024, 1, 9), 5)).to eq(Date.new(2024, 1, 12))
    end
  end

  describe ".weeks_between" do
    let(:jan1) { Date.new(2024, 1, 1) }

    it "returns 2 for 14 days apart" do
      expect(DateUtils.weeks_between(jan1, Date.new(2024, 1, 15))).to eq(2)
    end

    it "returns 4 for 28 days apart" do
      expect(DateUtils.weeks_between(jan1, Date.new(2024, 1, 29))).to eq(4)
    end

    it "returns 0 for the same date" do
      expect(DateUtils.weeks_between(jan1, jan1)).to eq(0)
    end

    it "returns 52 for approximately one year" do
      expect(DateUtils.weeks_between(jan1, Date.new(2024, 12, 30))).to eq(52)
    end
  end
end
