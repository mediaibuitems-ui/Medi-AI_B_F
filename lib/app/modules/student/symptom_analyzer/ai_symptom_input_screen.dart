import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ai_symptom_input_controller.dart';
import 'package:medi_ai/config/app_theme.dart';

class AiSymptomInputScreen extends GetView<AiSymptomInputController> {
  const AiSymptomInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Symptom Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.toNamed('/symptom-analyzer-history');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() => Stack(
              children: [
                Column(
                  children: [
                    // Top Warning Banner
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This tool provides general guidance, not medical advice. For emergencies, call your local emergency number immediately.',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stepper(
                        type: StepperType.vertical,
                        currentStep: controller.currentStep.value,
                        onStepContinue: controller.nextStep,
                        onStepCancel: controller.previousStep,
                        controlsBuilder: (BuildContext context, ControlsDetails details) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Row(
                              children: <Widget>[
                                ElevatedButton(
                                  onPressed: details.onStepContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(controller.currentStep.value == controller.totalSteps - 1 ? 'Analyze' : 'Continue'),
                                ),
                                if (controller.currentStep.value > 0) ...[
                                  const SizedBox(width: 12),
                                  TextButton(
                                    onPressed: details.onStepCancel,
                                    child: const Text('Back'),
                                  ),
                                ]
                              ],
                            ),
                          );
                        },
                        steps: [
                          _buildDemographicsStep(),
                          _buildRedFlagsStep(),
                          _buildContextStep(),
                        ],
                      ),
                    ),
                  ],
                ),
                if (controller.isLoading.value)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            )),
      ),
    );
  }

  Step _buildDemographicsStep() {
    return Step(
      title: const Text('Basic Information'),
      isActive: controller.currentStep.value >= 0,
      content: Form(
        key: controller.formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller.ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Biological Sex', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Male', 'Female', 'Other'].map((sex) {
                return Obx(() => ChoiceChip(
                      label: Text(sex),
                      selected: controller.biologicalSex.value.toLowerCase() == sex.toLowerCase(),
                      onSelected: (_) => controller.biologicalSex.value = sex.toLowerCase(),
                    ));
              }).toList(),
            ),
            Obx(() {
              if (controller.biologicalSex.value == 'female') {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Are you pregnant?', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Yes', 'No', 'Not Sure'].map((opt) {
                          return ChoiceChip(
                            label: Text(opt),
                            selected: controller.pregnancyStatus.value == opt,
                            onSelected: (_) => controller.pregnancyStatus.value = opt,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Step _buildRedFlagsStep() {
    return Step(
      title: const Text('Emergency Symptoms'),
      subtitle: const Text('Select any that apply'),
      isActive: controller.currentStep.value >= 1,
      content: Form(
        key: controller.formKeys[1],
        child: Column(
          children: controller.redFlagsOptions.map((flag) {
            return Obx(() => CheckboxListTile(
                  title: Text(flag, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                  value: controller.selectedRedFlags.contains(flag),
                  onChanged: (_) => controller.toggleRedFlag(flag),
                  activeColor: Colors.red,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ));
          }).toList(),
        ),
      ),
    );
  }



  Step _buildContextStep() {
    return Step(
      title: const Text('Medical Context'),
      isActive: controller.currentStep.value >= 2,
      content: Form(
        key: controller.formKeys[2],
        child: Column(
          children: [
            TextFormField(
              controller: controller.existingConditionsController,
              decoration: InputDecoration(
                labelText: 'Existing Conditions (Optional)',
                hintText: 'e.g., Asthma, Diabetes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.currentMedicationsController,
              decoration: InputDecoration(
                labelText: 'Current Medications (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.allergiesController,
              decoration: InputDecoration(
                labelText: 'Allergies (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
