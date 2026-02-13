//
//  MedicalSchoolData.swift
//  Rounds
//
//  Medical school database for leaderboard feature
//

import Foundation

// MARK: - School Type

enum SchoolType: String, Codable, CaseIterable {
    case md = "MD"
    case do_ = "DO"

    var displayName: String {
        switch self {
        case .md: return "MD"
        case .do_: return "DO"
        }
    }
}

// MARK: - Medical School Model

struct MedicalSchool: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let state: String
    let type: SchoolType

    var fullName: String {
        "\(name) (\(type.displayName))"
    }

    var stateFullName: String {
        USStates.fullName(for: state) ?? state
    }
}

// MARK: - US States

enum USStates {
    static let all: [(code: String, name: String)] = [
        ("AL", "Alabama"),
        ("AK", "Alaska"),
        ("AZ", "Arizona"),
        ("AR", "Arkansas"),
        ("CA", "California"),
        ("CO", "Colorado"),
        ("CT", "Connecticut"),
        ("DE", "Delaware"),
        ("DC", "District of Columbia"),
        ("FL", "Florida"),
        ("GA", "Georgia"),
        ("HI", "Hawaii"),
        ("ID", "Idaho"),
        ("IL", "Illinois"),
        ("IN", "Indiana"),
        ("IA", "Iowa"),
        ("KS", "Kansas"),
        ("KY", "Kentucky"),
        ("LA", "Louisiana"),
        ("ME", "Maine"),
        ("MD", "Maryland"),
        ("MA", "Massachusetts"),
        ("MI", "Michigan"),
        ("MN", "Minnesota"),
        ("MS", "Mississippi"),
        ("MO", "Missouri"),
        ("MT", "Montana"),
        ("NE", "Nebraska"),
        ("NV", "Nevada"),
        ("NH", "New Hampshire"),
        ("NJ", "New Jersey"),
        ("NM", "New Mexico"),
        ("NY", "New York"),
        ("NC", "North Carolina"),
        ("ND", "North Dakota"),
        ("OH", "Ohio"),
        ("OK", "Oklahoma"),
        ("OR", "Oregon"),
        ("PA", "Pennsylvania"),
        ("PR", "Puerto Rico"),
        ("RI", "Rhode Island"),
        ("SC", "South Carolina"),
        ("SD", "South Dakota"),
        ("TN", "Tennessee"),
        ("TX", "Texas"),
        ("UT", "Utah"),
        ("VT", "Vermont"),
        ("VA", "Virginia"),
        ("WA", "Washington"),
        ("WV", "West Virginia"),
        ("WI", "Wisconsin"),
        ("WY", "Wyoming")
    ]

    static func fullName(for code: String) -> String? {
        all.first { $0.code == code }?.name
    }

    static func code(for name: String) -> String? {
        all.first { $0.name.lowercased() == name.lowercased() }?.code
    }
}

// MARK: - Medical School Database

enum MedicalSchoolDatabase {

    /// All US medical schools (MD and DO)
    static let allSchools: [MedicalSchool] = mdSchools + doSchools

    /// Schools grouped by state
    static var schoolsByState: [String: [MedicalSchool]] {
        Dictionary(grouping: allSchools, by: { $0.state })
    }

    /// Get schools for a specific state
    static func schools(in state: String) -> [MedicalSchool] {
        allSchools.filter { $0.state == state }
    }

    /// Search schools by name
    static func search(_ query: String) -> [MedicalSchool] {
        guard !query.isEmpty else { return allSchools }
        let lowercased = query.lowercased()
        return allSchools.filter { school in
            school.name.lowercased().contains(lowercased) ||
            school.stateFullName.lowercased().contains(lowercased)
        }
    }

    /// Find school by ID
    static func school(withID id: String) -> MedicalSchool? {
        allSchools.first { $0.id == id }
    }

    // MARK: - MD Schools (LCME Accredited)

    static let mdSchools: [MedicalSchool] = [
        // Alabama
        MedicalSchool(id: "uab-som", name: "UAB Heersink School of Medicine", state: "AL", type: .md),
        MedicalSchool(id: "usa-com", name: "University of South Alabama College of Medicine", state: "AL", type: .md),

        // Arizona
        MedicalSchool(id: "arizona-com-phoenix", name: "University of Arizona College of Medicine - Phoenix", state: "AZ", type: .md),
        MedicalSchool(id: "arizona-com-tucson", name: "University of Arizona College of Medicine - Tucson", state: "AZ", type: .md),
        MedicalSchool(id: "mayo-alix-az", name: "Mayo Clinic Alix School of Medicine - Arizona", state: "AZ", type: .md),

        // Arkansas
        MedicalSchool(id: "uams-com", name: "University of Arkansas for Medical Sciences", state: "AR", type: .md),

        // California
        MedicalSchool(id: "ucsd-som", name: "UC San Diego School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "ucsf-som", name: "UCSF School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "ucla-dgsom", name: "UCLA David Geffen School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "uci-som", name: "UC Irvine School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "ucd-som", name: "UC Davis School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "ucr-som", name: "UC Riverside School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "usc-ksom", name: "USC Keck School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "stanford-som", name: "Stanford University School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "llu-som", name: "Loma Linda University School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "cusm", name: "California University of Science and Medicine", state: "CA", type: .md),
        MedicalSchool(id: "kaiser-bsm", name: "Kaiser Permanente Bernard J. Tyson School of Medicine", state: "CA", type: .md),
        MedicalSchool(id: "cnu-com", name: "California Northstate University College of Medicine", state: "CA", type: .md),

        // Colorado
        MedicalSchool(id: "cu-som", name: "University of Colorado School of Medicine", state: "CO", type: .md),

        // Connecticut
        MedicalSchool(id: "yale-som", name: "Yale School of Medicine", state: "CT", type: .md),
        MedicalSchool(id: "uconn-som", name: "UConn School of Medicine", state: "CT", type: .md),
        MedicalSchool(id: "quinnipiac-netter", name: "Quinnipiac University Frank H. Netter MD School of Medicine", state: "CT", type: .md),

        // District of Columbia
        MedicalSchool(id: "gw-smhs", name: "George Washington University School of Medicine", state: "DC", type: .md),
        MedicalSchool(id: "georgetown-som", name: "Georgetown University School of Medicine", state: "DC", type: .md),
        MedicalSchool(id: "howard-com", name: "Howard University College of Medicine", state: "DC", type: .md),

        // Florida
        MedicalSchool(id: "uf-com", name: "University of Florida College of Medicine", state: "FL", type: .md),
        MedicalSchool(id: "usf-morsani", name: "USF Health Morsani College of Medicine", state: "FL", type: .md),
        MedicalSchool(id: "um-miller", name: "University of Miami Miller School of Medicine", state: "FL", type: .md),
        MedicalSchool(id: "fsu-com", name: "Florida State University College of Medicine", state: "FL", type: .md),
        MedicalSchool(id: "fiu-hwcom", name: "FIU Herbert Wertheim College of Medicine", state: "FL", type: .md),
        MedicalSchool(id: "ucf-com", name: "UCF College of Medicine", state: "FL", type: .md),
        MedicalSchool(id: "fau-schmidt", name: "FAU Charles E. Schmidt College of Medicine", state: "FL", type: .md),
        MedicalSchool(id: "mayo-alix-fl", name: "Mayo Clinic Alix School of Medicine - Florida", state: "FL", type: .md),

        // Georgia
        MedicalSchool(id: "emory-som", name: "Emory University School of Medicine", state: "GA", type: .md),
        MedicalSchool(id: "mcg-au", name: "Medical College of Georgia at Augusta University", state: "GA", type: .md),
        MedicalSchool(id: "morehouse-som", name: "Morehouse School of Medicine", state: "GA", type: .md),
        MedicalSchool(id: "mercer-som", name: "Mercer University School of Medicine", state: "GA", type: .md),

        // Hawaii
        MedicalSchool(id: "hawaii-jabsom", name: "University of Hawaii John A. Burns School of Medicine", state: "HI", type: .md),

        // Illinois
        MedicalSchool(id: "northwestern-fsm", name: "Northwestern University Feinberg School of Medicine", state: "IL", type: .md),
        MedicalSchool(id: "uchicago-pritzker", name: "University of Chicago Pritzker School of Medicine", state: "IL", type: .md),
        MedicalSchool(id: "rush-mc", name: "Rush Medical College", state: "IL", type: .md),
        MedicalSchool(id: "uic-com", name: "University of Illinois College of Medicine", state: "IL", type: .md),
        MedicalSchool(id: "loyola-ssom", name: "Loyola University Chicago Stritch School of Medicine", state: "IL", type: .md),
        MedicalSchool(id: "siu-som", name: "Southern Illinois University School of Medicine", state: "IL", type: .md),
        MedicalSchool(id: "rosalind-franklin", name: "Rosalind Franklin University Chicago Medical School", state: "IL", type: .md),
        MedicalSchool(id: "carle-illinois", name: "Carle Illinois College of Medicine", state: "IL", type: .md),

        // Indiana
        MedicalSchool(id: "iu-som", name: "Indiana University School of Medicine", state: "IN", type: .md),

        // Iowa
        MedicalSchool(id: "uiowa-ccom", name: "University of Iowa Carver College of Medicine", state: "IA", type: .md),

        // Kansas
        MedicalSchool(id: "ku-som", name: "University of Kansas School of Medicine", state: "KS", type: .md),

        // Kentucky
        MedicalSchool(id: "uk-com", name: "University of Kentucky College of Medicine", state: "KY", type: .md),
        MedicalSchool(id: "uofl-som", name: "University of Louisville School of Medicine", state: "KY", type: .md),

        // Louisiana
        MedicalSchool(id: "tulane-som", name: "Tulane University School of Medicine", state: "LA", type: .md),
        MedicalSchool(id: "lsu-nola", name: "LSU Health New Orleans School of Medicine", state: "LA", type: .md),
        MedicalSchool(id: "lsu-shreveport", name: "LSU Health Shreveport School of Medicine", state: "LA", type: .md),

        // Maryland
        MedicalSchool(id: "jhu-som", name: "Johns Hopkins University School of Medicine", state: "MD", type: .md),
        MedicalSchool(id: "umd-som", name: "University of Maryland School of Medicine", state: "MD", type: .md),
        MedicalSchool(id: "usuhs", name: "Uniformed Services University School of Medicine", state: "MD", type: .md),

        // Massachusetts
        MedicalSchool(id: "harvard-hms", name: "Harvard Medical School", state: "MA", type: .md),
        MedicalSchool(id: "bu-chobanian", name: "Boston University Chobanian & Avedisian School of Medicine", state: "MA", type: .md),
        MedicalSchool(id: "tufts-usm", name: "Tufts University School of Medicine", state: "MA", type: .md),
        MedicalSchool(id: "umass-chan", name: "UMass Chan Medical School", state: "MA", type: .md),

        // Michigan
        MedicalSchool(id: "umich-med", name: "University of Michigan Medical School", state: "MI", type: .md),
        MedicalSchool(id: "wayne-state-som", name: "Wayne State University School of Medicine", state: "MI", type: .md),
        MedicalSchool(id: "msu-chm", name: "Michigan State University College of Human Medicine", state: "MI", type: .md),
        MedicalSchool(id: "wmu-stryker", name: "Western Michigan University Homer Stryker M.D. School of Medicine", state: "MI", type: .md),
        MedicalSchool(id: "oakland-beaumont", name: "Oakland University William Beaumont School of Medicine", state: "MI", type: .md),
        MedicalSchool(id: "central-michigan", name: "Central Michigan University College of Medicine", state: "MI", type: .md),

        // Minnesota
        MedicalSchool(id: "umn-med", name: "University of Minnesota Medical School", state: "MN", type: .md),
        MedicalSchool(id: "mayo-alix-mn", name: "Mayo Clinic Alix School of Medicine - Minnesota", state: "MN", type: .md),

        // Mississippi
        MedicalSchool(id: "ummc-som", name: "University of Mississippi School of Medicine", state: "MS", type: .md),

        // Missouri
        MedicalSchool(id: "wustl-som", name: "Washington University School of Medicine in St. Louis", state: "MO", type: .md),
        MedicalSchool(id: "slu-som", name: "Saint Louis University School of Medicine", state: "MO", type: .md),
        MedicalSchool(id: "umkc-som", name: "University of Missouri-Kansas City School of Medicine", state: "MO", type: .md),
        MedicalSchool(id: "mizzou-som", name: "University of Missouri School of Medicine", state: "MO", type: .md),

        // Nebraska
        MedicalSchool(id: "unmc-com", name: "University of Nebraska Medical Center College of Medicine", state: "NE", type: .md),
        MedicalSchool(id: "creighton-som", name: "Creighton University School of Medicine", state: "NE", type: .md),

        // Nevada
        MedicalSchool(id: "unlv-som", name: "UNLV Kirk Kerkorian School of Medicine", state: "NV", type: .md),
        MedicalSchool(id: "unr-med", name: "University of Nevada, Reno School of Medicine", state: "NV", type: .md),

        // New Hampshire
        MedicalSchool(id: "dartmouth-geisel", name: "Dartmouth Geisel School of Medicine", state: "NH", type: .md),

        // New Jersey
        MedicalSchool(id: "rutgers-njms", name: "Rutgers New Jersey Medical School", state: "NJ", type: .md),
        MedicalSchool(id: "rutgers-rwjms", name: "Rutgers Robert Wood Johnson Medical School", state: "NJ", type: .md),
        MedicalSchool(id: "cooper-rowan", name: "Cooper Medical School of Rowan University", state: "NJ", type: .md),
        MedicalSchool(id: "hackensack-meridian", name: "Hackensack Meridian School of Medicine", state: "NJ", type: .md),

        // New Mexico
        MedicalSchool(id: "unm-som", name: "University of New Mexico School of Medicine", state: "NM", type: .md),

        // New York
        MedicalSchool(id: "columbia-vp", name: "Columbia University Vagelos College of Physicians and Surgeons", state: "NY", type: .md),
        MedicalSchool(id: "cornell-weill", name: "Weill Cornell Medicine", state: "NY", type: .md),
        MedicalSchool(id: "nyu-grossman", name: "NYU Grossman School of Medicine", state: "NY", type: .md),
        MedicalSchool(id: "nyu-li", name: "NYU Grossman Long Island School of Medicine", state: "NY", type: .md),
        MedicalSchool(id: "mssm-icahn", name: "Icahn School of Medicine at Mount Sinai", state: "NY", type: .md),
        MedicalSchool(id: "einstein-com", name: "Albert Einstein College of Medicine", state: "NY", type: .md),
        MedicalSchool(id: "rochester-smda", name: "University of Rochester School of Medicine and Dentistry", state: "NY", type: .md),
        MedicalSchool(id: "buffalo-jacobs", name: "University at Buffalo Jacobs School of Medicine", state: "NY", type: .md),
        MedicalSchool(id: "suny-downstate", name: "SUNY Downstate Health Sciences University", state: "NY", type: .md),
        MedicalSchool(id: "suny-upstate", name: "SUNY Upstate Medical University", state: "NY", type: .md),
        MedicalSchool(id: "stony-brook", name: "Renaissance School of Medicine at Stony Brook", state: "NY", type: .md),
        MedicalSchool(id: "albany-amc", name: "Albany Medical College", state: "NY", type: .md),
        MedicalSchool(id: "nymc", name: "New York Medical College", state: "NY", type: .md),
        MedicalSchool(id: "hofstra-zucker", name: "Donald and Barbara Zucker School of Medicine at Hofstra/Northwell", state: "NY", type: .md),

        // North Carolina
        MedicalSchool(id: "duke-som", name: "Duke University School of Medicine", state: "NC", type: .md),
        MedicalSchool(id: "unc-som", name: "UNC School of Medicine", state: "NC", type: .md),
        MedicalSchool(id: "wake-forest", name: "Wake Forest University School of Medicine", state: "NC", type: .md),
        MedicalSchool(id: "ecu-brody", name: "East Carolina University Brody School of Medicine", state: "NC", type: .md),

        // North Dakota
        MedicalSchool(id: "und-smhs", name: "University of North Dakota School of Medicine", state: "ND", type: .md),

        // Ohio
        MedicalSchool(id: "osu-com", name: "The Ohio State University College of Medicine", state: "OH", type: .md),
        MedicalSchool(id: "case-som", name: "Case Western Reserve University School of Medicine", state: "OH", type: .md),
        MedicalSchool(id: "uc-com", name: "University of Cincinnati College of Medicine", state: "OH", type: .md),
        MedicalSchool(id: "toledo-com", name: "University of Toledo College of Medicine", state: "OH", type: .md),
        MedicalSchool(id: "neomed", name: "Northeast Ohio Medical University", state: "OH", type: .md),
        MedicalSchool(id: "wright-state", name: "Wright State University Boonshoft School of Medicine", state: "OH", type: .md),
        MedicalSchool(id: "cleveland-clinic", name: "Cleveland Clinic Lerner College of Medicine", state: "OH", type: .md),

        // Oklahoma
        MedicalSchool(id: "ou-com", name: "University of Oklahoma College of Medicine", state: "OK", type: .md),

        // Oregon
        MedicalSchool(id: "ohsu-som", name: "Oregon Health & Science University School of Medicine", state: "OR", type: .md),

        // Pennsylvania
        MedicalSchool(id: "upenn-psom", name: "University of Pennsylvania Perelman School of Medicine", state: "PA", type: .md),
        MedicalSchool(id: "pitt-som", name: "University of Pittsburgh School of Medicine", state: "PA", type: .md),
        MedicalSchool(id: "jefferson-skmc", name: "Thomas Jefferson University Sidney Kimmel Medical College", state: "PA", type: .md),
        MedicalSchool(id: "temple-lksom", name: "Temple University Lewis Katz School of Medicine", state: "PA", type: .md),
        MedicalSchool(id: "drexel-com", name: "Drexel University College of Medicine", state: "PA", type: .md),
        MedicalSchool(id: "psu-com", name: "Penn State College of Medicine", state: "PA", type: .md),
        MedicalSchool(id: "geisinger-commonwealth", name: "Geisinger Commonwealth School of Medicine", state: "PA", type: .md),

        // Puerto Rico
        MedicalSchool(id: "upr-som", name: "University of Puerto Rico School of Medicine", state: "PR", type: .md),
        MedicalSchool(id: "ponce-health", name: "Ponce Health Sciences University School of Medicine", state: "PR", type: .md),
        MedicalSchool(id: "sju-som", name: "San Juan Bautista School of Medicine", state: "PR", type: .md),
        MedicalSchool(id: "ucm", name: "Universidad Central del Caribe School of Medicine", state: "PR", type: .md),

        // Rhode Island
        MedicalSchool(id: "brown-alpert", name: "Brown University Warren Alpert Medical School", state: "RI", type: .md),

        // South Carolina
        MedicalSchool(id: "musc-com", name: "Medical University of South Carolina College of Medicine", state: "SC", type: .md),
        MedicalSchool(id: "usc-som-columbia", name: "University of South Carolina School of Medicine Columbia", state: "SC", type: .md),
        MedicalSchool(id: "usc-som-greenville", name: "University of South Carolina School of Medicine Greenville", state: "SC", type: .md),

        // South Dakota
        MedicalSchool(id: "usd-sanford", name: "University of South Dakota Sanford School of Medicine", state: "SD", type: .md),

        // Tennessee
        MedicalSchool(id: "vanderbilt-som", name: "Vanderbilt University School of Medicine", state: "TN", type: .md),
        MedicalSchool(id: "uthsc-com", name: "University of Tennessee Health Science Center College of Medicine", state: "TN", type: .md),
        MedicalSchool(id: "meharry-som", name: "Meharry Medical College School of Medicine", state: "TN", type: .md),
        MedicalSchool(id: "etsu-quillen", name: "East Tennessee State University Quillen College of Medicine", state: "TN", type: .md),

        // Texas
        MedicalSchool(id: "ut-southwestern", name: "UT Southwestern Medical School", state: "TX", type: .md),
        MedicalSchool(id: "bcm", name: "Baylor College of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "uthsc-houston", name: "UTHealth Houston McGovern Medical School", state: "TX", type: .md),
        MedicalSchool(id: "uthsc-sa", name: "UT Health San Antonio Long School of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "utmb-galveston", name: "UTMB School of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "ut-austin-dell", name: "Dell Medical School at UT Austin", state: "TX", type: .md),
        MedicalSchool(id: "ut-tyler", name: "UT Tyler School of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "ut-rgv", name: "UTRGV School of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "ttu-hsc", name: "Texas Tech University Health Sciences Center School of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "ttu-ep", name: "Texas Tech University Health Sciences Center El Paso Paul L. Foster School of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "tamu-com", name: "Texas A&M School of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "tcu-burnett", name: "TCU Burnett School of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "uh-com", name: "University of Houston College of Medicine", state: "TX", type: .md),
        MedicalSchool(id: "sam-houston", name: "Sam Houston State University College of Osteopathic Medicine", state: "TX", type: .md),

        // Utah
        MedicalSchool(id: "utah-som", name: "University of Utah School of Medicine", state: "UT", type: .md),
        MedicalSchool(id: "noorda-com", name: "Noorda College of Osteopathic Medicine", state: "UT", type: .md),

        // Vermont
        MedicalSchool(id: "uvm-lcom", name: "University of Vermont Larner College of Medicine", state: "VT", type: .md),

        // Virginia
        MedicalSchool(id: "uva-som", name: "University of Virginia School of Medicine", state: "VA", type: .md),
        MedicalSchool(id: "vcu-som", name: "Virginia Commonwealth University School of Medicine", state: "VA", type: .md),
        MedicalSchool(id: "evms", name: "Eastern Virginia Medical School", state: "VA", type: .md),
        MedicalSchool(id: "vt-carilion", name: "Virginia Tech Carilion School of Medicine", state: "VA", type: .md),

        // Washington
        MedicalSchool(id: "uw-som", name: "University of Washington School of Medicine", state: "WA", type: .md),
        MedicalSchool(id: "wsu-elson", name: "Washington State University Elson S. Floyd College of Medicine", state: "WA", type: .md),

        // West Virginia
        MedicalSchool(id: "wvu-som", name: "West Virginia University School of Medicine", state: "WV", type: .md),
        MedicalSchool(id: "marshall-jcesom", name: "Marshall University Joan C. Edwards School of Medicine", state: "WV", type: .md),

        // Wisconsin
        MedicalSchool(id: "mcw", name: "Medical College of Wisconsin", state: "WI", type: .md),
        MedicalSchool(id: "uw-smph", name: "University of Wisconsin School of Medicine and Public Health", state: "WI", type: .md)
    ]

    // MARK: - DO Schools (COCA Accredited)

    static let doSchools: [MedicalSchool] = [
        // Alabama
        MedicalSchool(id: "acom", name: "Alabama College of Osteopathic Medicine", state: "AL", type: .do_),

        // Arizona
        MedicalSchool(id: "atsu-soma", name: "A.T. Still University School of Osteopathic Medicine in Arizona", state: "AZ", type: .do_),
        MedicalSchool(id: "mwu-azcom", name: "Midwestern University Arizona College of Osteopathic Medicine", state: "AZ", type: .do_),

        // California
        MedicalSchool(id: "westernu-comp", name: "Western University of Health Sciences COMP", state: "CA", type: .do_),
        MedicalSchool(id: "touro-ca", name: "Touro University California College of Osteopathic Medicine", state: "CA", type: .do_),

        // Colorado
        MedicalSchool(id: "rvu-com", name: "Rocky Vista University College of Osteopathic Medicine", state: "CO", type: .do_),

        // Florida
        MedicalSchool(id: "nsu-kpcom", name: "Nova Southeastern University Dr. Kiran C. Patel College of Osteopathic Medicine", state: "FL", type: .do_),
        MedicalSchool(id: "lecom-bradenton", name: "Lake Erie College of Osteopathic Medicine - Bradenton", state: "FL", type: .do_),

        // Georgia
        MedicalSchool(id: "pcom-ga", name: "PCOM Georgia", state: "GA", type: .do_),

        // Idaho
        MedicalSchool(id: "icom", name: "Idaho College of Osteopathic Medicine", state: "ID", type: .do_),

        // Illinois
        MedicalSchool(id: "mwu-ccom", name: "Midwestern University Chicago College of Osteopathic Medicine", state: "IL", type: .do_),

        // Indiana
        MedicalSchool(id: "marian-com", name: "Marian University College of Osteopathic Medicine", state: "IN", type: .do_),

        // Iowa
        MedicalSchool(id: "dmu-com", name: "Des Moines University College of Osteopathic Medicine", state: "IA", type: .do_),

        // Kansas
        MedicalSchool(id: "kc-university-com", name: "Kansas City University College of Osteopathic Medicine - Kansas City", state: "KS", type: .do_),

        // Kentucky
        MedicalSchool(id: "uofpike-kycom", name: "University of Pikeville Kentucky College of Osteopathic Medicine", state: "KY", type: .do_),

        // Maine
        MedicalSchool(id: "une-com", name: "University of New England College of Osteopathic Medicine", state: "ME", type: .do_),

        // Michigan
        MedicalSchool(id: "msu-com", name: "Michigan State University College of Osteopathic Medicine", state: "MI", type: .do_),

        // Mississippi
        MedicalSchool(id: "wc-msdcom", name: "William Carey University College of Osteopathic Medicine", state: "MS", type: .do_),

        // Missouri
        MedicalSchool(id: "atsu-kcom", name: "A.T. Still University Kirksville College of Osteopathic Medicine", state: "MO", type: .do_),
        MedicalSchool(id: "kcu-com-mo", name: "Kansas City University College of Osteopathic Medicine", state: "MO", type: .do_),

        // Montana
        MedicalSchool(id: "rvu-montana", name: "Rocky Vista University College of Osteopathic Medicine - Montana", state: "MT", type: .do_),

        // Nevada
        MedicalSchool(id: "touro-nv", name: "Touro University Nevada College of Osteopathic Medicine", state: "NV", type: .do_),

        // New Jersey
        MedicalSchool(id: "rowan-som", name: "Rowan-Virtua School of Osteopathic Medicine", state: "NJ", type: .do_),

        // New York
        MedicalSchool(id: "nyitcom", name: "New York Institute of Technology College of Osteopathic Medicine", state: "NY", type: .do_),
        MedicalSchool(id: "touro-nycom", name: "Touro College of Osteopathic Medicine", state: "NY", type: .do_),

        // North Carolina
        MedicalSchool(id: "campbell-com", name: "Campbell University Jerry M. Wallace School of Osteopathic Medicine", state: "NC", type: .do_),

        // Ohio
        MedicalSchool(id: "ohio-heritage", name: "Ohio University Heritage College of Osteopathic Medicine", state: "OH", type: .do_),

        // Oklahoma
        MedicalSchool(id: "osu-com", name: "Oklahoma State University Center for Health Sciences College of Osteopathic Medicine", state: "OK", type: .do_),

        // Pennsylvania
        MedicalSchool(id: "pcom", name: "Philadelphia College of Osteopathic Medicine", state: "PA", type: .do_),
        MedicalSchool(id: "lecom-erie", name: "Lake Erie College of Osteopathic Medicine", state: "PA", type: .do_),

        // South Carolina
        MedicalSchool(id: "pcom-sc", name: "PCOM South Carolina", state: "SC", type: .do_),

        // Tennessee
        MedicalSchool(id: "lmu-dcom", name: "Lincoln Memorial University DeBusk College of Osteopathic Medicine", state: "TN", type: .do_),

        // Texas
        MedicalSchool(id: "tcom-unthsc", name: "University of North Texas Health Science Center Texas College of Osteopathic Medicine", state: "TX", type: .do_),
        MedicalSchool(id: "shsu-com", name: "Sam Houston State University College of Osteopathic Medicine", state: "TX", type: .do_),

        // Utah
        MedicalSchool(id: "rvu-utah", name: "Rocky Vista University College of Osteopathic Medicine - Utah", state: "UT", type: .do_),
        MedicalSchool(id: "noorda", name: "Noorda College of Osteopathic Medicine", state: "UT", type: .do_),

        // Virginia
        MedicalSchool(id: "vcom-vb", name: "Edward Via College of Osteopathic Medicine - Virginia", state: "VA", type: .do_),
        MedicalSchool(id: "lucom", name: "Liberty University College of Osteopathic Medicine", state: "VA", type: .do_),

        // Washington
        MedicalSchool(id: "pnwu-com", name: "Pacific Northwest University of Health Sciences College of Osteopathic Medicine", state: "WA", type: .do_),

        // West Virginia
        MedicalSchool(id: "wvsom", name: "West Virginia School of Osteopathic Medicine", state: "WV", type: .do_)
    ]
}
