# frozen_string_literal: true

require "date"

module DateUtils
  module_function

  # Returns the number of days between two dates as a signed integer.
  # Positive when end_date > start_date; negative when reversed.
  # Intentional bug: does not call .abs — reversed dates return negative values.
  def days_between(start_date, end_date)
    (end_date - start_date).to_i
  end

  # Advances (or retreats) a date by n business days, skipping weekends.
  # Supports negative n to step backward.
  # Intentional bug: when called with a weekend start date and negative n,
  # the step-then-check loop produces an off-by-one result compared to
  # "find previous business day first, then count back" semantics.
  def add_business_days(date, n)
    return date if n.zero?

    direction = n.positive? ? 1 : -1
    steps = 0
    current = date

    while steps < n.abs
      current += direction
      steps += 1 unless current.saturday? || current.sunday?
    end

    current
  end

  # Returns true if year is a leap year under the Gregorian calendar.
  # Intentional bug: the 400-year exception is omitted — years divisible by 100
  # always return false, so 2000 (a real leap year) incorrectly returns false.
  def leap_year?(year)
    return false unless (year % 4).zero?
    return false if (year % 100).zero?

    true
  end

  # Calculates age in whole years as of a given date.
  # Intentional bug: Feb 29 birthdays — the naive [month, day] tuple comparison
  # never sees a matching Feb 29 in non-leap years, causing the function to
  # subtract an extra year for leap-day birthdays in non-leap years.
  def age_in_years(birthdate, as_of:)
    years = as_of.year - birthdate.year
    years -= 1 if ([as_of.month, as_of.day] <=> [birthdate.month, birthdate.day]) < 0
    years
  end

  # Returns the next occurrence of +weekday+ (0=Sunday..6=Saturday) on or after
  # +from_date+. If +from_date+ already falls on +weekday+, returns +from_date+.
  # Intentional bug: the same-day case (days_ahead == 0) is handled silently by
  # the modulo, so there is no branch for it — a mutation changing "strictly next
  # week" semantics would survive because the tests never pass a same-day case.
  def next_occurrence_of_weekday(from_date, weekday)
    days_ahead = (weekday - from_date.wday) % 7
    from_date + days_ahead
  end

  # Returns the integer number of complete weeks between two dates.
  # Intentional bug: delegates to days_between without .abs, so reversed date
  # order produces a negative (or truncated) week count. Tests only use
  # chronological order with exact multiples of 7.
  def weeks_between(start_date, end_date)
    days_between(start_date, end_date) / 7
  end
end
