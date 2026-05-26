# frozen_string_literal: true

require "date"

module DateUtils
  module_function

  # Returns the number of days between two dates as an unsigned integer.
  # Always positive regardless of date order.
  # Fixed: added .abs to handle reversed date order correctly.
  def days_between(start_date, end_date)
    (end_date - start_date).to_i.abs
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
  # Fixed: full Gregorian rule — divisible by 400 overrides the 100-year exception.
  def leap_year?(year)
    return false unless (year % 4).zero?
    return false if (year % 100).zero? && !(year % 400).zero?

    true
  end

  # Calculates age in whole years as of a given date.
  # Fixed: clamps Feb 29 birthdays to Feb 28 for non-leap year comparison.
  def age_in_years(birthdate, as_of:)
    years = as_of.year - birthdate.year
    bday = birthdate.month == 2 && birthdate.day == 29 ? 28 : birthdate.day
    years -= 1 if ([as_of.month, as_of.day] <=> [birthdate.month, bday]) < 0
    years
  end

  # Returns the next occurrence of +weekday+ (0=Sunday..6=Saturday) strictly after
  # +from_date+. If +from_date+ already falls on +weekday+, returns next week's occurrence.
  # Fixed: same-day case now advances 7 days instead of returning from_date.
  def next_occurrence_of_weekday(from_date, weekday)
    days_ahead = (weekday - from_date.wday) % 7
    days_ahead = 7 if days_ahead.zero?
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
