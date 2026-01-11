//
//  AboutView.swift
//  Stepordle
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingFeedback = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Title
                    VStack(spacing: 16) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Rounds")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // How to Play
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How to Play")
                            .font(.title2)
                            .bold()
                        
                        InstructionRow(
                            icon: "1.circle.fill",
                            title: "Read the Clinical Clues",
                            description: "Start with the first hint and read the patient presentation."
                        )
                        
                        InstructionRow(
                            icon: "2.circle.fill",
                            title: "Make Your Diagnosis",
                            description: "Enter your diagnosis guess. You have 5 attempts total."
                        )
                        
                        InstructionRow(
                            icon: "3.circle.fill",
                            title: "Progressive Hints",
                            description: "After each wrong guess, a new clinical clue is revealed automatically. Once all clues are revealed, your next guess is your final chance."
                        )
                        
                        InstructionRow(
                            icon: "exclamationmark.circle.fill",
                            title: "Final Guess",
                            description: "When all hints are revealed, you get one last attempt. If it's wrong, the answer is revealed and the round ends."
                        )
                        
                        InstructionRow(
                            icon: "4.circle.fill",
                            title: "Earn Points",
                            description: "Fewer guesses and hints = higher score! 500 base points - 100 per guess - 50 per extra hint."
                        )
                        
                        InstructionRow(
                            icon: "5.circle.fill",
                            title: "Build Your Streak",
                            description: "Play daily to maintain your winning streak and track your progress."
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Rounds")
                            .font(.title2)
                            .bold()
                        
                        Text("Rounds is a medical diagnosis game designed to help medical students master USMLE Step 1 high-yield topics through engaging gameplay. Each case presents progressive clinical clues that guide you toward the correct diagnosis.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Text("Practice pattern recognition, clinical reasoning, and diagnostic skills while having fun!")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Categories Covered
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories Covered")
                            .font(.title2)
                            .bold()
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            CategoryTag(name: "Cardiology", color: .red)
                            CategoryTag(name: "Neurology", color: .purple)
                            CategoryTag(name: "Pulmonology", color: .blue)
                            CategoryTag(name: "Gastroenterology", color: .orange)
                            CategoryTag(name: "Endocrinology", color: .green)
                            CategoryTag(name: "Nephrology", color: .cyan)
                            CategoryTag(name: "Hematology", color: .pink)
                            CategoryTag(name: "Infectious Disease", color: .yellow)
                            CategoryTag(name: "Rheumatology", color: .indigo)
                            CategoryTag(name: "Psychiatry", color: .mint)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    Button {
                        showingFeedback = true
                    } label: {
                        Label("Send Feedback", systemImage: "paperplane.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .cornerRadius(12)
                    }
                    
                    // Medical Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Important Disclaimer", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        
                        Text("Rounds is for educational and study purposes only. It is not intended to diagnose, treat, cure, or prevent any disease or medical condition. The content provided should not be used as a substitute for professional medical advice, diagnosis, or treatment.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. Never disregard professional medical advice or delay in seeking it because of something you have learned in this app.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Support Links
                    VStack(spacing: 12) {
                        Link(destination: URL(string: "https://braskgroup.com/stepordle.html")!) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                        }
                        
                        Link(destination: URL(string: "https://braskgroup.com/stepordle.html")!) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Terms of Service")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                        }
                        
                        Link(destination: URL(string: "mailto:support@braskgroup.com?subject=Rounds%20Support")!) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Contact Support")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                        }
                        
                        Link(destination: URL(string: "https://braskgroup.com")!) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                Text("More from Brask Group")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("Made with ❤️ for medical students")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("© 2025 Brask Group LLC")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Brask Group LLC dba Rounds")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackSheet()
        }
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Category Tag
struct CategoryTag: View {
    let name: String
    let color: Color
    
    var body: some View {
        Text(name)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(8)
    }
}

#Preview {
    AboutView()
}
